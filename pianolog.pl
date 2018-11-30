use_module(midi).
use_module(wave).

% play a sequence of notes imported from a MIDI file
playMIDI :-
	% convert the MIDI file into a sequence of notes
	convertFromMIDI(Notes), 

	% transpose the notes and specify the output file
	transpose(Notes, TransposedNotes),
	outputFile(FileName),

	% generate the output file in WAV format
	convertToWave(TransposedNotes, FileName).

% play a sequence of notes given by user input
play :-
	write("Please enter a sequence of notes according to the following format: [OctaveID|Note|(#/b)?]"), nl,
	write("Example input: 3C 3D# 4Db"), nl,
	read(Input),

	catch(
		parseInput(Input, Notes),
		_, misformattedNotes),

	transpose(Notes, TransposedNotes),
	outputFile(FileName),

	convertToWave(TransposedNotes, FileName).

% ERROR HANDLING
% outputs a Wrong Format error message and stops execution
misformattedNotes :-
	write("Please ensure your notes are formatted correctly. Example input: 3C 3D# 4Ab"), nl, false.

% parseInput(Input, Notes) is true if InputArray is an array of integers that are numerical representations of each note separated by spaces in the string Input 
parseInput(Input, Notes) :-
	split_string(Input, " ", "", InputArray),
	parseInputArray(InputArray, Notes).

% parseInputArray(InputArray, NoteArray) is true if the elements of NoteArray are numerical representation of the string elements of InputArray
parseInputArray([], []).
parseInputArray([Input|InputArray], [Note|NoteArray]) :-
	convertToNote(Input, Note),
	parseInputArray(InputArray, NoteArray).


% converts a note from an atom input into an integer note value
convertToNote(Input, Note) :-
	% convert the input into an array of characters
	atom_chars(Input, [OctID, Letter| []]),
	% convert the octave identifier into a number
	atom_number(OctID, OctNum),
	% convert the note from letter form into a number
	note(Letter, LetterNum),
	% calculate the corresponding note value
	Note is (OctNum * 12 + 12) + LetterNum.

% flat (b)
convertToNote(Input, Note) :-
	% convert the input into an array of characters
	atom_chars(Input, [OctID, Letter, 'b'| []]),
	% convert the octave identifier into a number
	atom_number(OctID, OctNum),
	% convert the note from letter form into a number
	note(Letter, LetterNum),
	% calculate the corresponding note value
	Note is (OctNum * 12 + 12 - 1) + LetterNum.

% sharp (#)
convertToNote(Input, Note) :-
	% convert the input into an array of characters
	atom_chars(Input, [OctID, Letter, '#'| []]),
	% convert the octave identifier into a number
	atom_number(OctID, OctNum),
	% convert the note from letter form into a number
	note(Letter, LetterNum),
	% calculate the corresponding note value
	Note is (OctNum * 12 + 12 + 1) + LetterNum.

% relation of each note in an octave and its corresponding numerical value
note('C', 0).
note('D', 2).
note('E', 4).
note('F', 5).
note('G', 7).
note('A', 9).
note('B', 11).

% TRANPOSITION
% transpose(Notes, TransposedNotes) is true if the elements of TransposedNotes are the elements of Notes transposed by the user input.
transpose(Notes, TransposedNotes) :-
    write("Do you want to transpose? Give a number between [-12, 12]: "), nl,
    read(TransposeBy),
    transposeNotes(Notes, TransposeBy, TransposedNotes).

% transposeNotes(Notes, TransposeBy, TransposedNotes) is true if the elements of TrnasposedNotes are the elements of Notes transposed by TransposeBy semitones
transposeNotes([], _, []).
transposeNotes([Note|NoteArray], TransposeBy, [TransposedNote|TransposedNoteArray]) :-
	TransposedNote is Note + TransposeBy,
	transposeNotes(NoteArray, TransposeBy, TransposedNoteArray).

% OUTPUT FILE NAME
% allows the user to specify the name of the output file
outputFile(FilePath) :-
	write("Please choose a name for the output file."), nl,
	read(FileName),
	string_concat(FileName, ".wav", FilePath).
