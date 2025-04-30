/*
 * @Module: Concretizer
 * @Desc:   Module that contains all the functionality to concretize verbs
 * @Auth:   Borja Velasco -> code, comments
 */
module Generation::Concretizer

/******************************************************************************/
// --- General modules imports -------------------------------------------------
import util::Math;
import List;
import Set;
import Map;

/******************************************************************************/
// --- Own modules imports -----------------------------------------------------
import Generation::ADT::Module;
import Generation::ADT::Verb;
import Generation::ADT::Chunk;
import Generation::Exception;
import Generation::Check;

import Annotation::ADT::Verb;

import Utils;

/******************************************************************************/
// --- Public concretize functions ---------------------------------------------

/*
 * @Name:   concretize
 * @Desc:   Function that concretizes the verbs to use in a chunk
 * @Params: \module -> Module of the chunk
 *          chunk   -> Generation chunk
 *          entry   -> Entry coords to the chunk
 *          width   -> Width of the chunk
 *          height  -> Height of the chunk
 * @Ret:    Tuple with the winning and challengeing playtraces
 */
tuple[tuple[list[list[GenerationVerbConcretized]], Coords],tuple[list[list[GenerationVerbConcretized]], Coords]] concretize(GenerationModule \module, GenerationChunk chunk, Coords entry, tuple[int,int] pattern_max_size, tuple[int,int] chunk_size) {
    tuple[
        tuple[
            list[list[GenerationVerbConcretized]] verbs, 
            Coords exit
        ] main_playtrace,
        tuple[
            list[list[GenerationVerbConcretized]] verbs, 
            Coords exit
        ] alt_playtrace
    ] concretized = <
        <[], <-1,-1>>,
        <[], <-1,-1>>
        >;


    switch(chunk) {
        case generation_chunk_default_win(_,_,_,_)     : concretized = concretize_default(\module, chunk.main_verbs, entry, pattern_max_size, chunk_size);
        case generation_chunk_default_fail(_,_,_,_)    : concretized = concretize_default(\module, chunk.main_verbs, entry, pattern_max_size, chunk_size);
        case generation_chunk_challenge_win(_,_,_,_,_) : concretized = concretize_challenge(\module, chunk, entry, pattern_max_size, chunk_size);
        case generation_chunk_challenge_fail(_,_,_,_,_): concretized = concretize_challenge(\module, chunk, entry, pattern_max_size, chunk_size);
    }

    return concretized;
}

/*
 * @Name:   concretize_check_future_position_exited
 * @Desc:   Function that checks if the future position to add will make us 
 *          exit from the chunk
 * @Param:  position_current  -> Dictionary with the current positions
 *          index             -> Index of the verb's subchunk to include
 *          direction         -> Direction of the verb
 *          width             -> Chunk width
 *          height            -> Chunk height
 * @Ret:    Boolean indicating if we exit or not
 */
bool concretize_check_future_position_exited(map[int keys, Coords coords] position_current, int index, str direction, tuple[int width, int height] chunk_size) {
    for(int i <- [index..size(position_current.keys)]) {
        if      (direction == "up"    && position_current[i].y-1 == -1)                return true;
        else if (direction == "left"  && position_current[i].x-1 == -1)                return true;
        else if (direction == "right" && position_current[i].x+1 == chunk_size.width)  return true;
        else if (direction == "down"  && position_current[i].y+1 == chunk_size.height) return true;
    }

    return false;
}

/*
 * @Name:   concretize_check_future_pattern_fit
 * @Desc:   Function that checks if the pattern that will be applied fits
 * @Param:  position_current  -> Dictionary with the current positions
 *          index             -> Index of the verb's subchunk to include
 *          direction         -> Direction of the verb
 *          width             -> Chunk width
 *          height            -> Chunk height
 * @Ret:    Boolean indicating if it fits
 */
bool concretize_check_future_pattern_fit(map[int keys, Coords coords] position_current, int index, tuple[int width, int height] pattern_size, str direction, tuple[int width, int height] chunk_size) {
    if      (direction == "up"    && position_current[index].y > pattern_size.height)                           return true;
    else if (direction == "right" && (chunk_size.width - position_current[index].x - 1) > pattern_size.width)   return true;
    else if (direction == "down"  && (chunk_size.height - position_current[index].y - 1) > pattern_size.height) return true;
    return false;
}

/*
 * @Name:   concretize_update_position_current
 * @Desc:   Function that updates the position current after adding one more 
 *          concrete verb
 * @Param:  position_current  -> Dictionary with the current positions
 *          index             -> Index of the verb's subchunk to include
 *          direction         -> Direction of the verb
 * @Ret:    Updated position current
 */
map[int, Coords] concretize_update_position_current(map[int keys, Coords coords] position_current, int index, str direction) {
    for(int i <- [index..size(position_current.keys)]) {
        if      (direction == "up")    position_current[i].y -= 1;
        else if (direction == "right") position_current[i].x += 1;
        else if (direction == "left")  position_current[i].x -= 1;
        else if (direction == "down")  position_current[i].y += 1;
    }

    return position_current;
}

/*
 * @Name:   concretize_check_position_current_exited
 * @Desc:   Function that checks if the last verb included made us exit from 
 *          the chunk
 * @Param:  position_current  -> Dictionary with the current positions
 *          index             -> Index of the verb's subchunk to include
 *          width             -> Chunk width
 *          height            -> Chunk height
 * @Ret:    Updated position current
 */
bool concretize_check_position_current_exited(map[int keys, Coords coords] position_current, int index, tuple[int width, int height] chunk_size) {
    for(int i <- [index..size(position_current.keys)]) {
        if (check_exited_right(chunk_size, position_current[i])
            || check_exited_left(position_current[i])
            || check_exited_up(position_current[i]) 
            || check_exited_down(chunk_size, position_current[i])) return true;
    }
    return false;
}

/*
 * @Name:   concretize_delete_unused
 * @Desc:   Function that deletes those verbs that are after the chunk exit
 * @Param:  verbs_concretized -> List of concretized verbs
 *          position_current  -> Dictionary with the current positions
 *          width             -> Chunk width
 *          height            -> Chunk height
 * @Ret:    List of concretized verbs and updated position_current
 */
tuple[list[list[GenerationVerbConcretized]], map[int,Coords]] concretize_delete_unused(list[list[GenerationVerbConcretized]] verbs_concretized, map[int keys, Coords coords] position_current, tuple[int width, int height] chunk_size) {
    int exit_num = min(
        [i | int i <- [0..size(position_current.keys)], 
             position_current[i].x == -1
             || position_current[i].y == -1 
             || position_current[i].x == chunk_size.width 
             || position_current[i].y == chunk_size.height
        ]
        );

    for (int i <- [(exit_num+1)..size(position_current.keys)]) {
        verbs_concretized = remove(verbs_concretized, i);
        position_current = delete(position_current, i);
    }

    return <verbs_concretized, position_current>;
}

/*
 * @Name:   concretize_concat
 * @Desc:   Function that concats adjacent subchunks that use the same verbs
 * @Params: concretized_verbs -> List of concretized verbs
 *          position_current  -> Map with the positions after each subchunk
 * @Ret:    Tuple with the list of concated concretized verbs and their 
 *          corresponding positions
 */
tuple[list[list[GenerationVerbConcretized]], map[int,Coords]] concretize_concat(list[list[GenerationVerbConcretized]] concretized_verbs, map[int, Coords] position_current) {
    list[list[GenerationVerbConcretized]] concretized_verbs_concated = [];
    map[int, Coords] position_current_concated = ();

    if (concretized_verbs == []) return <concretized_verbs, position_current>;

    int i = 0;
    int subchunk_num = 0;
    while(i < size(concretized_verbs)) {
        list[GenerationVerbConcretized] subchunk = concretized_verbs[i];

        Coords position_current_coords = position_current[i];
        list[int] neighbors_eq = concretize_get_neighbors_equivalent(concretized_verbs, i);

        i += 1;

        for(int n <- neighbors_eq) {
            subchunk += concretized_verbs[n];
            position_current_coords = position_current[i];
            i += 1;
        }

        concretized_verbs_concated += [subchunk];
        position_current_concated[subchunk_num] = position_current_coords;
        subchunk_num += 1;
    }

    return <concretized_verbs_concated, position_current_concated>;
}

/*
 * @Name:   concretize_get_neighbors_equivalent
 * @Desc:   Function that gets the index of those neighbor subchunks that use 
 *          the same verb of the given one. By neighbor we refer to those chunks
 *          that are next (towards the right of the list) and that are adjacent
 * @Params: concretized_verbs -> List of concretized verbs
 *          index             -> Index of the current subchunk
 * @Ret:    List with the indexes of the next neighbors that use the same index
 */
list[int] concretize_get_neighbors_equivalent(list[list[GenerationVerbConcretized]] concretized_verbs, int index) {
    list[int] neighbors_eq = [];
    list[GenerationVerbConcretized] subchunk_current = [];
    list[GenerationVerbConcretized] subchunk_next = [];
    GenerationVerbConcretized verb_current = generation_verb_concretized_empty();
    GenerationVerbConcretized verb_next = generation_verb_concretized_empty();
    int i = -1;

    subchunk_current = concretized_verbs[index];
    if (subchunk_current == []) return [];
    verb_current = subchunk_current[0];

    i = index+1;
    if (i >= size(concretized_verbs)) return [];

    subchunk_next = concretized_verbs[i];
    verb_next = (subchunk_next != []) ? subchunk_next[0] : generation_verb_concretized_empty();
    i+=1;
    while((verb_next == verb_current || verb_next is generation_verb_concretized_empty) && i < size(concretized_verbs)) {
        neighbors_eq += [i-1];

        subchunk_next = concretized_verbs[i];
        verb_next = (subchunk_next != []) ? subchunk_next[0] : generation_verb_concretized_empty();
        i+=1;
    }

    return neighbors_eq;
}

/******************************************************************************/
// --- Public concretize main playtrace functions ------------------------------

/*
 * @Name:   concretize_main_playtrace
 * @Desc:   Function that concretizes the verbs to be applied in a chunk. It 
 *          transforms a regular-like expresion such as [crawl+, climb+] to an
 *          specific sequence of verbs
 * @Param:  chunk  -> GenertionChunk to be concretized
 *          width  -> Chunk width
 *          height -> Chunk height
 * @Ret:    List of concretized verbs
 */
tuple[list[list[GenerationVerbConcretized]], map[int,Coords]] concretize_main_playtrace(GenerationModule \module, list[GenerationVerbExpression] verbs_abs, Coords entry, tuple[int,int] pattern_max_size, tuple[int,int] chunk_size) {
    map[int, Coords] position_current = ();

    for (int i <- [0..size(verbs_abs)]) position_current[i] = entry;
    tuple[list[list[GenerationVerbConcretized]] verbs_concretized, map[int, Coords] position_current] res = <[], position_current>;

    res = concretize_playtrace_init(\module, verbs_abs, res.verbs_concretized, res.position_current, chunk_size, 0);
    res = concretize_playtrace_extend(\module, verbs_abs, res.verbs_concretized, res.position_current, pattern_max_size, chunk_size, 0);
    res = concretize_concat(res.verbs_concretized, res.position_current);

    return <res.verbs_concretized, res.position_current>;
}

/*
 * @Name:   concretize_playtrace_init
 * @Desc:   Function that concretizes the mandatory verbs to be applied in a 
 *          chunk
 * @Param:  verbs_abs        -> GenerationVerbExpressions to be concretized
 *          position_current -> Dictionary with the current positions
 * @Ret:    List of concretized verbs and updated position_current
 */
tuple[list[list[GenerationVerbConcretized]], map[int,Coords]] concretize_playtrace_init(GenerationModule \module, list[GenerationVerbExpression] verbs_abs, list[list[GenerationVerbConcretized]] verbs_concretized, map[int, Coords] position_current, tuple[int,int] chunk_size, int index) {
    int end_index = 0;

    for (int i <- [0..size(verbs_abs)]) {
        str verb_name = verbs_abs[i].verb;
        str verb_specification = verbs_abs[i].specification;
        str verb_modifier = verbs_abs[i].modifier;
        str verb_direction = (verbs_abs[i].direction != "_") ? verbs_abs[i].direction : generation_module_get_verb(\module, verb_name, verb_specification, "_").direction;

        list[GenerationVerbConcretized] basket = [];
        if (verb_modifier == "+" || verb_modifier == "") {
            position_current = concretize_update_position_current(position_current, index+i, verb_direction);
            exited = concretize_check_position_current_exited(position_current, index+i, chunk_size);

            if (!exited) {
                GenerationVerbConcretized verb_concretized = generation_verb_concretized(verb_name, verb_specification, verb_direction);
                basket += [verb_concretized];
            }
        }

        verbs_concretized += [basket];
        end_index = i;
    }

    if (verbs_concretized[end_index+index] == []) {
        verbs_concretized = (end_index+index != 0) ? verbs_concretized[0..end_index+index] : [];
        
        if (end_index+index-1 != -1) {
            position_current[end_index+index-1] = position_current[end_index+index];
            position_current                    = delete(position_current, end_index+index);
        }
    }

    return <verbs_concretized, position_current>;
}

/*
 * @Name:   concretize_playtrace_extend
 * @Desc:   Function that concretizes all the verbs to be applied in a chunk
 *          (mandatory and non-mandatory)
 * @Param:  verbs_abs         -> GenerationVerbExpressions to be concretized
 *          verbs_concretized -> List of concretized verbs
 *          position_current  -> Dictionary with the current positions
 *          width             -> Chunk width
 *          height            -> Chunk height
 * @Ret:    List of concretized verbs and updated position_current
 */
tuple[list[list[GenerationVerbConcretized]], map[int,Coords]] concretize_playtrace_extend(GenerationModule \module, list[GenerationVerbExpression] verbs_abs, list[list[GenerationVerbConcretized]] verbs_concretized, map[int,Coords] position_current, tuple[int,int] pattern_max_size, tuple[int,int] chunk_size, int index) {
    int subchunk_num = size(verbs_abs);
    int subchunk_last_compulsory = max([i | int i <- [0..subchunk_num], verbs_abs[i].modifier == "+" || verbs_abs[i].modifier == ""] + [0]);
    bool subchunk_contains_end = concretize_contains_end(\module, verbs_abs);

    bool exited = (true in ([concretize_check_position_current_exited(position_current, i, chunk_size) | int i <- [0..subchunk_num]]));
    while (!exited && !subchunk_contains_end) {
        int i = arbInt(subchunk_num);

        str verb_name = verbs_abs[i].verb;
        str verb_specification = verbs_abs[i].specification;
        str verb_modifier = verbs_abs[i].modifier;
        VerbAnnotation verb = generation_module_get_verb(\module, verb_name, verb_specification, "_");
        str verb_direction = (verbs_abs[i].direction != "_") ? verbs_abs[i].direction : verb.direction;

        if(verb_modifier == "" 
           || (verb_modifier == "?" && size(verbs_concretized[i])== 1)) continue; 

        if (i < subchunk_last_compulsory
            && concretize_check_future_position_exited(position_current, i, verb_direction, chunk_size)) continue;

        position_current = concretize_update_position_current(position_current, i+index, verb_direction);
        exited = concretize_check_position_current_exited(position_current, i+index, chunk_size);
        if (!exited) {
            GenerationVerbConcretized verb_concretized = generation_verb_concretized(verb_name, verb_specification, verb_direction);
            verbs_concretized[i+index] += [verb_concretized];
        }

        if (subchunk_contains_end) exited = (arbInt(2) == 1); 
    }

    tuple[list[list[GenerationVerbConcretized]], map[int,Coords]] res = <verbs_concretized, position_current>;
    if (!subchunk_contains_end) res = concretize_delete_unused(verbs_concretized, position_current, chunk_size);

    return res;
}

bool concretize_contains_end(GenerationModule \module, list[GenerationVerbExpression] verbs_abs) {
    for (GenerationVerbExpression v <- verbs_abs) {
        VerbAnnotation verb = generation_module_get_verb(\module, v.verb, v.specification, v.direction);
        if (verb_is_end(verb)) return true;
    }

    return false;
}

/*****************************************************************************/
// --- Public concretize alternative playtrace functions ----------------------

/*
 * @Name:   concretize_alternative_playtrace
 * @Desc:   Function that concretized the fail playtrace of a chunk. Intuitively
 *          it copies a part of the winning playtrace and extends another part 
 *          that is new
 * @Params: \module -> Module of the chunk
 *          alt_verbs_abs -> Abstract list of failing verbs
 *          entry -> Entry coords to the chunk
 *          main_verbs_abs -> Abstract list of winning verbs
 *          main_verbs_concretized -> List of winning verbs concretized
 *          main_position_current -> Map with partial positions
 * @Ret:    Tuple with the list of concretized verbs and the map of partial 
 *          current positions
 */
tuple[list[list[GenerationVerbConcretized]], map[int,Coords]] concretize_alternative_playtrace(GenerationModule \module, list[GenerationVerbExpression] alt_verbs_abs,  Coords entry, list[GenerationVerbExpression] main_verbs_abs, list[list[GenerationVerbConcretized]] main_verbs_concretized, map[int, Coords] main_position_current, tuple[int,int] pattern_max_size, tuple[int,int] chunk_size) {
    tuple[list[list[GenerationVerbConcretized]] verbs_concretized, map[int, Coords] position_current] res = <[],()>;
    list[GenerationVerbExpression] alt_verbs_abs_subpt = [];
    list[GenerationVerbExpression] alt_verbs_abs_newpt = [];
    list[list[GenerationVerbConcretized]] verbs_concretized = [];
    map[int, Coords] position_current = ();
    int newpt_index = -1;

    if (alt_verbs_abs == []) return res;

    newpt_index = concretize_alternative_playtrace_get_subplaytrace_index(alt_verbs_abs, main_verbs_abs);
    if (newpt_index == -1) exception_playtraces_alt_not_subplaytrace();

    alt_verbs_abs_subpt = alt_verbs_abs[0..newpt_index];
    alt_verbs_abs_newpt = alt_verbs_abs[newpt_index..size(alt_verbs_abs)];

    res = concretize_alternative_playtrace_subplaytrace(
        alt_verbs_abs_subpt,
        res.verbs_concretized,
        res.position_current,
        main_verbs_concretized,
        main_position_current,
        newpt_index,
        chunk_size
        );

    if (res.position_current == ()) res.position_current = (0:entry);
    res = concretize_alternative_playtrace_newplaytrace(
        \module,
        alt_verbs_abs_newpt,
        res.verbs_concretized,
        res.position_current,
        newpt_index,
        pattern_max_size,
        chunk_size
        );

    res = concretize_concat(res.verbs_concretized, res.position_current);

    return <res.verbs_concretized, res.position_current>;
}   

/*
 * @Name:   concretize_alternative_playtrace_subplaytrace
 * @Desc:   Function that concretizes the subplaytrace of the failing playtrace
 *          that is also part of the winning playtrace
 * @Params: alt_verbs_abs         -> failing verbs part of the subplaytrace
 *          alt_verbs_concretized -> Current list of failing verbs concretized
 *          alt_position_current  -> Current map of partial current positions
 *          main_verbs_concretized  -> List of winning verbs concretized
 *          main_position_current   -> Map of win partial current positions
 * @Ret:    Tuple with list of fail verbs concretized and position current updated
 */
tuple[list[list[GenerationVerbConcretized]], map[int, Coords]] concretize_alternative_playtrace_subplaytrace(list[GenerationVerbExpression] alt_verbs_abs, list[list[GenerationVerbConcretized]] alt_verbs_concretized, map[int, Coords] alt_position_current, list[list[GenerationVerbConcretized]] main_verbs_concretized, map[int, Coords] main_position_current, int newpt_index, tuple[int width, int height] chunk_size) {
    for (int i <- [0..newpt_index]) {
        alt_verbs_concretized    += [main_verbs_concretized[i]];

        alt_position_current[i]  = main_position_current[i];
        if      (check_exited_right(chunk_size, main_position_current[i])) alt_position_current[i].x -= 1; 
        else if (check_exited_left(main_position_current[i]))              alt_position_current[i].x += 1;
        else if (check_exited_down(chunk_size, main_position_current[i]))  alt_position_current[i].y -= 1;
        else if (check_exited_up(main_position_current[i]))                alt_position_current[i].y += 1;
    }

    return <alt_verbs_concretized, alt_position_current>;
}

/*
 * @Name:   concretize_alternative_playtrace_subplaytrace
 * @Desc:   Function that concretizes the subplaytrace of the failing playtrace
 *          that is also part of the winning playtrace. It first sets the initial
 *          position current of each of the corresponding subchunks to the value
 *          of the last position current of the subplaytrace and then includes
 *          the needed verbs
 * @Params: alt_verbs_abs         -> failing verbs part of the subplaytrace
 *          alt_verbs_concretized -> Current list of failing verbs concretized
 *          alt_position_current  -> Current map of partial current positions
 *          main_verbs_concretized  -> List of winning verbs concretized
 *          main_position_current   -> Map of win partial current positions
 * @Ret:    Tuple with list of fail verbs concretized and position current updated
 */
tuple[list[list[GenerationVerbConcretized]], map[int, Coords]] concretize_alternative_playtrace_newplaytrace(GenerationModule \module, list[GenerationVerbExpression] alt_verbs_abs, list[list[GenerationVerbConcretized]] alt_verbs_concretized, map[int, Coords] alt_position_current, int newpt_index, tuple[int,int] pattern_max_size, tuple[int,int] chunk_size) {
    for (int i <- [newpt_index..(size(alt_verbs_abs)+newpt_index)]) {
        tmp_index = (newpt_index-1 == -1) ? 0 : newpt_index-1;
        alt_position_current[i] = alt_position_current[tmp_index];
    }

    tuple[list[list[GenerationVerbConcretized]] verbs_concretized, map[int, Coords] position_current] res = <alt_verbs_concretized, alt_position_current>;

    res = concretize_playtrace_init(\module, alt_verbs_abs, res.verbs_concretized, res.position_current, chunk_size, newpt_index);
    res = concretize_playtrace_extend(\module, alt_verbs_abs, res.verbs_concretized, res.position_current, pattern_max_size, chunk_size, newpt_index);
    res = concretize_concat(res.verbs_concretized, res.position_current);

    return res;
}

/*
 * @Name:   concretize_alternative_playtrace_get_subplaytrace_index
 * @Desc:   Function that gets the index of when the subplaytrace of failing
 *          abstract verbs ends with respect to the winning abstract verbs
 * @Params: alt_verbs_abs -> failing verbs abstract
 *          main_verbs_abs  -> Winning verbs abstract 
 */
int concretize_alternative_playtrace_get_subplaytrace_index(list[GenerationVerbExpression] alt_verbs_abs, list[GenerationVerbExpression] main_verbs_abs) {
    for (int i <- [0..size(main_verbs_abs)]) {
        if(main_verbs_abs[i].verb != alt_verbs_abs[i].verb
           || (main_verbs_abs[i].verb == alt_verbs_abs[i].verb 
               && main_verbs_abs[i].specification != alt_verbs_abs[i].specification)
           || (main_verbs_abs[i].verb == alt_verbs_abs[i].verb 
               && main_verbs_abs[i].specification == alt_verbs_abs[i].specification
               && main_verbs_abs[i].direction != alt_verbs_abs[i].direction)) return i;
    }
    return -1;
}

/*****************************************************************************/
// --- Public concretize default functions ------------------------------------

tuple[tuple[list[list[GenerationVerbConcretized]], Coords],tuple[list[list[GenerationVerbConcretized]], Coords]] concretize_default(GenerationModule \module, list[GenerationVerbExpression] verbs_abs, Coords entry, tuple[int,int] pattern_max_size, tuple[int,int] chunk_size) {
    tuple[
        list[list[GenerationVerbConcretized]] verbs,
        map[int,Coords] position_current
    ] main_concretized = concretize_main_playtrace(\module, verbs_abs, entry, pattern_max_size, chunk_size);

    int index_end = (size(main_concretized.verbs) == 0) ? 0 : size(main_concretized.verbs)-1;

    return <
        <main_concretized.verbs, main_concretized.position_current[index_end]>,
        <[],<-1,-1>>
        >;
}

/*****************************************************************************/
// --- Public concretize challenge functions ----------------------------------

/*
 * @Name:   concretize_challenge
 * @Desc:   Function that concretizes a challenge subchunk
 * @Params: \module -> Module of the chunk
 *          chunk -> Abstract chunk
 *          entry -> Entry coords to the chunk
 * @Ret:    Tuple with the list of concretized verbs and the map of partial 
 *          current positions
 */
tuple[tuple[list[list[GenerationVerbConcretized]], Coords], tuple[list[list[GenerationVerbConcretized]], Coords]] concretize_challenge(GenerationModule \module, GenerationChunk chunk,  Coords entry, tuple[int,int] pattern_max_size, tuple[int,int] chunk_size) {
    tuple[list[list[GenerationVerbConcretized]] verbs, map[int,Coords] position_current] main_concretized = <[], ()>;
    tuple[list[list[GenerationVerbConcretized]] verbs, map[int,Coords] position_current] alt_concretized = <[], ()>;

    main_concretized = concretize_main_playtrace(
        \module,
        chunk.main_verbs,
        entry,
        pattern_max_size,
        chunk_size
        );
    int index = (size(main_concretized.verbs) == 0) ? 0 : size(main_concretized.verbs)-1;
    Coords main_exit = main_concretized.position_current[index];

    alt_concretized = concretize_alternative_playtrace(
        \module,
        chunk.alt_verbs,
        entry,
        chunk.main_verbs, 
        main_concretized.verbs, 
        main_concretized.position_current,
        pattern_max_size,
        chunk_size
        );
    Coords alt_exit = alt_concretized.position_current[size(alt_concretized.verbs)-1];

    return <
        <main_concretized.verbs, main_exit>,
        <alt_concretized.verbs, alt_exit>
    >;
}