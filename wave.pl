:- module(wave, [convertToWave/2]).

% process the given array of notes and output it as a WAV file
convertToWave(NotesArray, ResultFileName) :-
	% catch any exceptions and return an error message
	catch(
		% given an array of notes, generate the coresponding header and data chunks
		playNotes(NotesArray, Header, NoteDataArray), 
		_, wrongFormat),

	% generate the result file with the given file name, header contents and notes
	generateResult(ResultFileName, Header, NoteDataArray),

	write("Your composition has been recorded"), nl,
	write("Thanks for playing :)").

% ERROR HANDLING
% outputs a Wrong Format error message and stops execution
wrongFormat :- write("Please provide notes within the range of 24 - 95."), nl, false.

% INFORMATION RETRIEVAL
% play the given array of notes and retrieve the WAV file header + data array
playNotes([], _, []).

% play note events
playNotes([noteEvent(Note, _)|[]], Header, [Data]) :-
	getNoteData(Note, 1, Header, Data).
playNotes([noteEvent(Note1, Time1), noteEvent(Note2, Time2)|NoteArray], Header, [Data|DataArray]) :-
	Duration is Time2 - Time1,
	getNoteData(Note1, Duration, Header, Data),
	playNotes([noteEvent(Note2,Time2)|NoteArray], _, DataArray).

% play regular notes
playNotes([Note|[]], Header, [Data]) :-
	getNoteData(Note, 0.5, Header, Data).
playNotes([Note|NoteArray], Header, [Data|DataArray]) :-
	getNoteData(Note, 0.5, Header, Data),
	playNotes(NoteArray, _, DataArray).


% take(N1, C, N2) is true when N2 is a list that contains the first C elements of N1
take(0, _, R) :- !, R = [].
take(N, C, [H|R]) :-
  call(C, [H|T]),
  M is N-1,
  take(M, T, R).

% infinite list of zeros
zero([0|zero]).

% gets the header and data contents for the specified note 
getNoteData(Note, Duration, NoteHeader, FinalData) :-
	Duration > 1,
	% generate the file path string to retrieve the sample note data
	string_concat("samples_16/", Note, FileName),
	string_concat(FileName, ".wav", FilePath),

	% open the file in read mode
	open(FilePath, read, Stream, [encoding(octet)]),
	
	% grab all parts of the file information - header, datasize and data
	getHeader(Stream, NoteHeader),
	getDataSize(Stream, _),
	getData(Stream, 176400, NoteData),

	NumZeros is round(176400 * Duration - 176400),
	NumZerosEven is NumZeros - NumZeros mod 2,

	take(NumZerosEven, zero, Zeros),
	append(NoteData, Zeros, FinalData),
	% close the stream
	close(Stream).

getNoteData(Note, Duration, NoteHeader, NoteData) :-
	Duration =< 1,
	% generate the file path string to retrieve the sample note data
	string_concat("samples_16/", Note, FileName),
	string_concat(FileName, ".wav", FilePath),

	% force the number of bytes to be even to prevent generating static noise
	NumBytes is round(176400 * Duration),
	NumBytesEven is NumBytes - NumBytes mod 2,

	% open the file in read mode
	open(FilePath, read, Stream, [encoding(octet)]),
	
	% grab all parts of the file information - header, datasize and data
	getHeader(Stream, NoteHeader),
	getDataSize(Stream, _),
	getData(Stream, NumBytesEven, NoteData),

	% close the stream
	close(Stream).

% INFORMATION RETRIEVAL HELPERS
% gets the header, data size, and data sections from the specified stream 
getHeader(Stream, Header) :- getBytes(732, Stream, Header).
getDataSize(Stream, DataSize) :- getBytes(4, Stream, DataSize).
getData(Stream, NumBytes, Data) :- getBytes(NumBytes, Stream, Data).

% getBytes(Number, Stream, BytesArray)
%	 Number => number of bytes to read 
% 	 Stream => stream to read from
% 	 BytesArray => array of Number bytes read from the Stream
getBytes(_, Stream, []) :-
	at_end_of_stream(Stream).
getBytes(1, Stream, [X]) :- 
	get_byte(Stream, X).
getBytes(Count, Stream, [X|R]) :-
	Count2 is Count - 1,
	get_byte(Stream, X),
	getBytes(Count2, Stream, R).


% OUTPUT HANDLING
% generates the result file with the given file name, header and data array
generateResult(FileName, _, []) :-
	open(FileName, write, Stream, [encoding(octet)]),
	close(Stream).
generateResult(FileName, Header, DataArray) :-
	open(FileName, write, Stream, [encoding(octet)]),
	putBytes(Stream, Header),
	putBytes(Stream, [255, 255, 255, 255]),

	% insert all pieces of data into the result Stream
	insertData(DataArray, Stream),

	% close the stream
	close(Stream).

	

% OUTPUT HELPERS
% inserts an array of Data chunks into the given stream
insertData([], _).
insertData([H|T], Stream) :-
	putBytes(Stream, H),
	insertData(T, Stream).

% inserts an array of Bytes into the given Stream
putBytes(Stream, [X]) :-
	put_byte(Stream, X).
putBytes(Stream, [X|R]) :-
	put_byte(Stream, X),
	putBytes(Stream, R).
