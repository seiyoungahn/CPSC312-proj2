:- module(midi, [convertFromMIDI/1]).

% converts a user-specified MIDI file into an array of notes
convertFromMIDI(Notes) :-
    % ask the user for a MIDI file to use as input
    write("Which MIDI file would you like to convert?: "), nl,
    read(FileName),

    % catch any exceptions and return an error mesage
    catch(
        % read the given MIDI file and generate a list of MIDI events
        readMIDI(FileName, MIDIEvents), 
        _ , missingFile),

    % translate the MIDI events into an array of notes
    unpackEvents(MIDIEvents, Notes).


% ERROR HANDLING
% outputs a Missing File error message and stops execution
missingFile :- write("Please make sure you have specified a valid .mid file."), nl,false.

% unpackEvents(EventArray, NoteArray) is true when NoteArray contains elements of EventArray which has note_on message
unpackEvents([], []).
unpackEvents([(event(_, note_off, _, _))|EventArray], NoteArray) :-
    unpackEvents(EventArray, NoteArray).
unpackEvents([(event(_, end, _, _))|EventArray], NoteArray) :-
    unpackEvents(EventArray, NoteArray).
unpackEvents([(event(_, note_on, Note, _))|EventArray], [Note|NoteArray]) :-
    unpackEvents(EventArray, NoteArray).
    
% readMIDI(FileName, Events) is true when Events is a list that contains all MIDI events in file FileName
% each element in Events is event(time, message, key, velocity)
readMIDI(FileName, Events) :-
    open(FileName, read, Stream, [encoding(octet)]),
    skipBytes(Stream, 22), % go to where the event starts
    getEvents(Stream, Events).

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

% getMessage(Stream, Message) is true if Message is the midi message represented by the byte at Stream pointer 
getMessage(Stream, note_on) :-
    peek_byte(Stream, Status),
    FirstHex is Status / 16,
    FirstHex is 9, % status byte is 0x9n
    get_byte(Stream, _).
getMessage(Stream, note_off) :-
    peek_byte(Stream, Status),
    FirstHex is Status / 16,
    FirstHex is 8, % status byte is 0x8n
    get_byte(Stream, _).
getMessage(Stream, end) :-
    peek_byte(Stream, Status),
    Status is 255, % status byte is 0xFF
    get_byte(Stream, _).

% skipBytes(Stream, N) is true when the pointer of the Stream is moved by N bytes
skipBytes(_, 0).
skipBytes(Stream, _) :-
    at_end_of_stream(Stream).
skipBytes(Stream, N) :-
    \+ at_end_of_stream(Stream),
    M is N-1,
    get_byte(Stream, _),
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

% convertVLQListToNum(L, N) is true if N is the decimal representation of the VLQ numbers in L 
convertVLQListToNum([], 0).
convertVLQListToNum([H], H).
convertVLQListToNum([L|R], N) :-
    length(R, Size),
    Factor is 2 ** (Size * 7),
    convertVLQListToNum(R, M),
    N is ((L-128) * Factor) + M.