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
playNotes([Note|NoteArray], Header, [Data|DataArray]) :-
	getNoteData(Note, Header, Data),
	playNotes(NoteArray, _, DataArray).

% gets the header and data contents for the specified note 
getNoteData(Note, NoteHeader, NoteData) :-
	% generate the file path string to retrieve the sample note data
	string_concat("samples/", Note, FileName),
	string_concat(FileName, ".wav", FilePath),

	% open the file in read mode
	open(FilePath, read, Stream, [encoding(octet)]),

	% grab all parts of the file information - header, datasize and data
	getHeader(Stream, NoteHeader),
	getDataSize(Stream, _),
	getData(Stream, NoteData),

	% close the stream
	close(Stream).



% INFORMATION RETRIEVAL HELPERS
% gets the header, data size, and data sections from the specified stream 
getHeader(Stream, Header) :- getBytes(732, Stream, Header).
getDataSize(Stream, DataSize) :- getBytes(4, Stream, DataSize).
getData(Stream, Data) :- getBytes(-1, Stream, Data).

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

