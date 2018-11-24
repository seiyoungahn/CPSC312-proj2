start :-
    write("Which MIDI file would you like to convert?: "), nl,
    read(FileName),
    readMIDI(FileName, MIDIEvents),
    write("MIDI events: "), write(MIDIEvents), nl.
    
% readMIDI(FileName, Events) is true when Events is a list that contains all MIDI events in file FileName
% each element in Events is event(time, message, key, velocity)
readMIDI(FileName, TransposedEvents) :-
    open(FileName, read, Stream, [encoding(octet)]),
    skipBytes(Stream, 12), % go to where the ticks per beat information is
    get_byte(Stream, Byte1),
    get_byte(Stream, Byte2),
    TicksPerBeat is Byte1 * 256 + Byte2,
    write("What is the BPM?: "), nl,
    read(BPM),
    write("Do you want to transpose? Give a number between [-12, 12]: "), nl,
    read(TransposeBy),
    SecondPerTick is 1 / (TicksPerBeat * BPM / 60),
    skipBytes(Stream, 8), % go to where the event starts
    getEvents(Stream, Events),
    convertEventTime(SecondPerTick, Events, TimedEvents),
    transposeEvents(TransposeBy, TimedEvents, TransposedEvents).


% transposeEvents(TransposeBy, L1, L2) is true if all events in L2 are same events in L1
% transposed by TransposeBy semitones
transposeEvents(TransposeBy, [], []).
transposeEvents(TransposeBy, [event(T1,M1,K1,V1)|R], [event(T1,M1,K2,V1)|L]) :-
    K2 is K1 + TransposeBy,
    transposeEvents(TransposeBy, R, L).

% convertEventTime(SecondPerTick, L1, L2) is true if L2 is a converted list of L1 such that
% all elements of L2 has absolute time computed from delta time of its corresponding element in L1
convertEventTime(SecondPerTick, [Event], [Event]).
convertEventTime(SecondPerTick, [event(T1,M1,K1,V1),event(DT2,M2,K2,V2)|R], [event(T1,M1,K1,V1)|L]) :-
    T2 is T1 + (DT2 * SecondPerTick),
    convertEventTime(SecondPerTick, [event(T2,M2,K2,V2)|R], L).

% getEvents(Stream, List) is true when List contains all the events that begins from the stream pointer
getEvents(Stream, []) :-
    at_end_of_stream(Stream).
getEvents(Stream, [event(DeltaTime,Message,Key,Velocity)|R]) :-
    \+ at_end_of_stream(Stream),
    readVLQ(Stream, DeltaTime),   % this will advance pointer!!
    getMessage(Stream, Message),
    get_byte(Stream, Key),
    get_byte(Stream, Velocity),
    getEvents(Stream, R).

getMessage(Stream, note_on) :-
    peek_byte(Stream, Status),
    FirstHex is Status / 16,
    FirstHex is 9, % status byte is 0x9n
    get_byte(Stream, A).
getMessage(Stream, note_off) :-
    peek_byte(Stream, Status),
    FirstHex is Status / 16,
    FirstHex is 8, % status byte is 0x8n
    get_byte(Stream, A).
getMessage(Stream, end) :-
    peek_byte(Stream, Status),
    Status is 255, % status byte is 0xFF
    get_byte(Stream, A).

skipBytes(Stream, 0).
skipBytes(Stream, N) :-
    at_end_of_stream(Stream).
skipBytes(Stream, N) :-
    \+ at_end_of_stream(Stream),
    M is N-1,
    get_byte(Stream, Byte),
    skipBytes(Stream, M).

% readVLQ(Stream, N) is true when N is the decimal representation of the variable number at the current stream pointer.
% WARNING: this will advance stream pointer to the end of the variable number
% ex) 1000 0001 0000 1001 => 137 (https://en.wikipedia.org/wiki/Variable-length_quantity)
readVLQ(Stream, N) :-
    getVLQByteList(Stream, VLQList),
    convertVLQListToNum(VLQList, N).

% getVLQByteList(Stream, L) is true when L contains all bytes that represent a single variable number
% starting from the stream pointer
getVLQByteList(Stream, [B]) :-
    peek_byte(Stream, Byte),
    Byte < 128,
    get_byte(Stream, B). % leading bit is 0
getVLQByteList(Stream, [B|L]) :-
    peek_byte(Stream, Byte),
    Byte > 127, % leading bit is 1
    get_byte(Stream, B),
    getVLQByteList(Stream, L).

convertVLQListToNum([], 0).
convertVLQListToNum([H], H).
convertVLQListToNum([L|R], N) :-
    length(R, Size),
    Factor is 2 ** (Size * 7),
    convertVLQListToNum(R, M),
    N is ((L-128) * Factor) + M.