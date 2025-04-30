/*
 * @Module: Chunk
 * @Desc:   Module that contains the functionality for the generation chunk
 * @Auth:   Borja Velasco -> code, comments
 */
module Generation::ADT::Chunk

/******************************************************************************/
// --- General modules imports -------------------------------------------------
import IO;

/******************************************************************************/
// --- Own modules imports -----------------------------------------------------
import Generation::ADT::Verb;

/******************************************************************************/
// --- Data structure defines --------------------------------------------------

/*
 * @Name:   GenerationChunk
 * @Desc:   Data structure that models a generation chunk
 */
data GenerationChunk
    = generation_chunk_default_win(
        str name,
        str \module,
        list[GenerationVerbExpression] main_verbs,
        str chunk_prev
        )
    | generation_chunk_default_fail(
        str name,
        str \module,
        list[GenerationVerbExpression] main_verbs,
        str chunk_prev
        )
    | generation_chunk_challenge_win(
        str name,
        str \module,
        list[GenerationVerbExpression] main_verbs,
        list[GenerationVerbExpression] alt_verbs,
        str chunk_prev
        )
    | generation_chunk_challenge_fail(
        str name,
        str \module,
        list[GenerationVerbExpression] main_verbs,
        list[GenerationVerbExpression] alt_verbs,
        str chunk_prev
        )
    | generation_chunk_empty()
    ;

/*
 * @Name:   GenerationChunk
 * @Desc:   Data structure that models a chunk
 */
data Chunk
    = chunk(str name, tuple[int width, int height] size, list[str] objects)
    | chunk_empty()
    ;

/******************************************************************************/
// --- Public functions --------------------------------------------------------

Chunk chunk_init(str name, tuple[int width, int height] size) {
    return chunk(name, size, ["." | _ <- [0..(size.width*size.height)]]);
}

list[list[str]] chunk_get_rows(Chunk chunk) {
    list[list[str]] rows= [];

    for (int j <- [0..chunk.size.height]) {
        rows += [chunk_get_row(chunk, j)];
    }

    return rows;
}

list[str] chunk_get_row(Chunk chunk, int index) {
    return chunk.objects[(chunk.size.width*index)..(chunk.size.width*(index+1))];
}

str chunk_to_string(Chunk chunk) {
    str chunk_str = "";

    int i = 0;
    for (str object <- chunk.objects) {
        chunk_str += object;
        chunk_str += "\t";
        i += 1;

        if (i % chunk.size.width == 0) chunk_str += "\n";
    }

    return chunk_str;
}

void chunk_print(Chunk chunk, loc file) {
    str chunk_printed = "";

    chunk_printed += readFile(file);
    chunk_printed += chunk_to_string(chunk);
    
    writeFile(file, chunk_printed);

    return;
}

str generation_chunk_get_playtrace_type(GenerationChunk chunk) {
    str \type = "";

    switch(chunk) {
        case generation_chunk_default_win(_,_,_,_): \type = "win";
        case generation_chunk_default_fail(_,_,_,_): \type = "fail";
        case generation_chunk_challenge_win(_,_,_,_,_): \type = "win";
        case generation_chunk_challenge_fail(_,_,_,_,_): \type = "fail";
    }
    return \type;
}

str generation_chunk_get_type(GenerationChunk chunk) {
    str \type = "";

    switch(chunk) {
        case generation_chunk_default_win(_,_,_,_): \type = "default";
        case generation_chunk_default_fail(_,_,_,_): \type = "default";
        case generation_chunk_challenge_win(_,_,_,_,_): \type = "challenge";
        case generation_chunk_challenge_fail(_,_,_,_,_): \type = "challenge";
    }
    return \type;
}