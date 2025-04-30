/*
 * @Module: Engine
 * @Desc:   Module that includes all the functionality to generate the desired 
 *          tutorial levels
 * @Auth:   Borja Velasco -> code, comments
 */
module Generation::Engine

/******************************************************************************/
// --- General modules imports -------------------------------------------------
import util::Eval;
import util::Math;
import util::Benchmark;
import List;
import IO;

/******************************************************************************/
// --- Own modules imports -----------------------------------------------------
import Generation::ADT::Command;
import Generation::ADT::Pattern;
import Generation::ADT::Rule;
import Generation::ADT::Module;
import Generation::ADT::Verb;
import Generation::ADT::Chunk;
import Generation::ADT::Level;
import Generation::Check;
import Generation::Compiler;
import Generation::Concretizer;
import Generation::Translator;
import Generation::Match;
import Generation::Exception;

import Annotation::ADT::Verb;

import Utils;

/******************************************************************************/
// --- Public Generation Functions ---------------------------------------------

/*
 * @Name:   generate
 * @Desc:   Function that generates all the specified levels
 * @Params: engine -> Generation engine
 * @Ret:    list[list[str]] given that a level is a list[str] and we are
 *          returning all levels generated
 */
void generate(GenerationEngine engine) {
    list[Level] levels_generated = [];
    real start_time = toReal(realTime());

    println("Generation started...");
    levels_generated = generate_levels(engine);
    println("Generation completed...\t\t\t(<(realTime()-start_time)/1000>s)");

    for (Level lvl <- levels_generated) level_print(lvl, |project://daedale-framework/src/Interface/bin/levels.out|);
    return;
}

/******************************************************************************/
// --- Private Generation Functions --------------------------------------------

/*
 * @Name:   generate_levels
 * @Desc:   Function that generates all the specified levels
 * @Params: engine -> Generation engine
 * @Ret:    list of gnerated levels
 */
list[Level] generate_levels(GenerationEngine engine) {
    list[Level] levels_generated = [generate_level(engine, name, engine.levels_draft[name]) | str name <- engine.levels_draft.names];
    return levels_generated;
}

/*
 * @Name:   generate_level
 * @Desc:   Function that generates a single level from a given draft
 * @Params: engine -> Generation engine
 *          level  -> Generation level
 * @Ret:    list[list[str]] given that a level is a list[str] and we are
 *          returning all levels generated
 */
Level generate_level(GenerationEngine engine, str level_name, GenerationLevel level_abs) {
    map[
        str name,
        tuple[
            str \type,
            str playtrace_type,
            Coords coords,
            Coords main_exit,
            bool main_taken,
            Coords alt_exit
            ] info
        ] chunks_generated = ();
    tuple[
        Chunk chunk_generated, 
        Coords main_exit,
        Coords alt_exit
        ] res = <chunk_empty(), <-1,-1>, <-1,-1>>;
    tuple[
        str \type,
        str playtrace_type,
        Coords coords,
        Coords main_exit,
        bool main_taken,
        Coords alt_exit
        ] chunk_prev_info = <
            "",
            "",
            <-1,-1>,
            <-1,-1>,
            false,
            <-1,-1>
        >;

    Level level_generated = level_init(level_name, <engine.config["chunk_size"].width, engine.config["chunk_size"].height>);

    real start_time = toReal(realTime());

    for (GenerationChunk chunk_abs <- level_abs.chunks) {
        if (chunk_abs.chunk_prev in chunks_generated) chunk_prev_info = chunks_generated[chunk_abs.chunk_prev];

        player_exit  = generate_player_exit(chunk_abs, chunk_prev_info);
        if (player_exit == chunk_prev_info.main_exit) {
            chunk_prev_info.main_taken = true;
            chunks_generated[chunk_abs.chunk_prev] = chunk_prev_info;
        }

        player_entry = generate_chunk_entry(engine, player_exit);
        chunk_coords = generate_chunk_coords(engine, player_exit, chunk_prev_info.coords);

        if (chunk_coords.x > level_generated.abs_size.x_max) level_generated.abs_size.x_max += 1;
        if (chunk_coords.x < level_generated.abs_size.x_min) level_generated.abs_size.x_min -= 1;
        if (chunk_coords.y > level_generated.abs_size.y_max) level_generated.abs_size.y_max += 1;
        if (chunk_coords.y < level_generated.abs_size.y_min) level_generated.abs_size.y_min -= 1;

        res = generate_chunk(engine, chunk_coords, chunk_abs, player_entry, player_exit);
        level_generated.chunks_generated[chunk_coords] = res.chunk_generated;
        chunks_generated[chunk_abs.name] = <
            generation_chunk_get_type(chunk_abs),
            generation_chunk_get_playtrace_type(chunk_abs),
            chunk_coords,
            res.main_exit,
            false,
            res.alt_exit
            >;
    }

    println("    <string_capitalize(level_name)> generated...\t\t\t(<(realTime()-start_time)/1000>s)");

    return level_generated;
}

Coords generate_chunk_entry(GenerationEngine engine, Coords player_exit) {
    Coords player_entry = player_exit;
    tuple[int,int] chunk_size = <engine.config["chunk_size"].width,engine.config["chunk_size"].height>;

    if (player_exit == <-1,-1>) return <0, toInt(engine.config["chunk_size"].height/2)>;

    if      (check_exited_right(chunk_size, player_exit)) player_entry.x = 0;
    else if (check_exited_left(player_exit))              player_entry.x = engine.config["chunk_size"].width-1;
    else if (check_exited_down(chunk_size, player_exit))  player_entry.y = 0;
    else if (check_exited_up(player_exit))                player_entry.y = engine.config["chunk_size"].height-1;

    return player_entry;
}

Coords generate_chunk_coords(GenerationEngine engine, Coords player_exit, Coords chunk_prev_coords) {
    Coords chunk_coords = chunk_prev_coords;

    tuple[int,int] chunk_size = <engine.config["chunk_size"].width,engine.config["chunk_size"].height>;

    if (player_exit == <-1,-1>) return <0,0>;

    if      (check_exited_right(chunk_size, player_exit)) chunk_coords.x += 1;
    else if (check_exited_left(player_exit))              chunk_coords.x -= 1;
    else if (check_exited_down(chunk_size, player_exit))  chunk_coords.y += 1;
    else if (check_exited_up(player_exit))                chunk_coords.y -= 1;

    return chunk_coords;
}

Coords generate_player_exit(GenerationChunk chunk_abs, tuple[str \type, str playtrace_type, Coords coords, Coords main_exit, bool main_taken, Coords alt_exit] chunk_prev_info) {
    Coords player_exit  = <-1,-1>;

    if (chunk_prev_info == <"","",<-1,-1>,<-1,-1>,false,<-1,-1>>) return <-1,-1>;

    if (chunk_prev_info.\type                             == "default")  player_exit = chunk_prev_info.main_exit;
    else if (chunk_prev_info.\type                        == "challenge"
        && chunk_prev_info.playtrace_type                 == "win"
        && generation_chunk_get_playtrace_type(chunk_abs) == "win")      player_exit = chunk_prev_info.main_exit;
    else if (chunk_prev_info.\type                        == "challenge"
        && chunk_prev_info.playtrace_type                 == "win"
        && generation_chunk_get_playtrace_type(chunk_abs) == "fail")     player_exit = chunk_prev_info.alt_exit;
    else if (chunk_prev_info.\type                        == "challenge"
        && chunk_prev_info.playtrace_type                 == "fail"
        && chunk_prev_info.main_taken                     == false)      player_exit = chunk_prev_info.main_exit;
    else if (chunk_prev_info.\type                        == "challenge"
        && chunk_prev_info.playtrace_type                 == "fail"
        && chunk_prev_info.main_taken                     == true)       player_exit = chunk_prev_info.alt_exit;

    return player_exit;
}

/*
 * @Name:   generate_chunk
 * @Desc:   Function that generates a chunk from a given chunk data
 * @Params: engine        -> Generation engine
 *          chunk         -> Generation chunk
 *          player_entry  -> Entry coords to the chunk
 * @Ret:    Generated chunk object
 */
tuple[Chunk, Coords, Coords] generate_chunk(GenerationEngine engine, Coords chunk_coords, GenerationChunk chunk_abs, Coords player_entry, Coords prechunk_exit) {
    Chunk chunk_generated = chunk_empty();

    tuple[
        tuple[
            list[list[GenerationVerbConcretized]] verbs, 
            Coords exit
        ] main_playtrace,
        tuple[
            list[list[GenerationVerbConcretized]] verbs, 
            Coords exit
        ] alt_playtrace
    ] concretized = concretize(
        engine.modules[chunk_abs.\module], 
        chunk_abs, 
        player_entry, 
        <
            engine.config["pattern_max_size"].width, 
            engine.config["pattern_max_size"].height
        >, 
        <
            engine.config["chunk_size"].width, 
            engine.config["chunk_size"].height
        >
        );

    tuple[
        list[VerbAnnotation] main_playtrace,
        list[VerbAnnotation] alt_playtrace
    ] verbs_translated = translate(
        engine.modules[chunk_abs.\module],
        concretized.main_playtrace.verbs,
        concretized.alt_playtrace.verbs
        );

    chunk_main_generated = chunk_empty();
    if (verbs_translated.main_playtrace != []) chunk_main_generated = generate_chunk(
        engine,
        chunk_abs,
        player_entry,
        prechunk_exit,
        concretized.main_playtrace.exit,
        verbs_translated.main_playtrace
        );

    chunk_alt_generated = chunk_empty();
    if (verbs_translated.alt_playtrace != []) chunk_alt_generated = generate_chunk(
        engine,
        chunk_abs,
        player_entry,
        prechunk_exit,
        concretized.alt_playtrace.exit,
        verbs_translated.alt_playtrace
        );

    if (chunk_main_generated is chunk_empty && chunk_alt_generated is chunk_empty) chunk_main_generated = generate_chunk(
        engine,
        chunk_abs,
        player_entry,
        prechunk_exit,
        concretized.main_playtrace.exit,
        []
        );

    chunk_generated = apply_merge(chunk_abs.name, chunk_main_generated, chunk_alt_generated);

    chunk_generated = apply_blanketize(engine, chunk_generated);

    if (chunk_coords == <0,0>) chunk_generated = apply_place_player(chunk_generated, player_entry);

    return <chunk_generated, concretized.main_playtrace.exit, concretized.alt_playtrace.exit>;
}

/*
 * @Name:   generate_chunk
 * @Desc:   Function that generates a chunk.
 * @Params: engine           -> Generation engine
 *          chunk_abs        -> Generation chunk
 *          player_entry     -> Player entry coords to the chunk
 *          verbs_translated -> List of verbs to apply to generate the chunk
 *          width            -> Width of the chunk
 *          height           -> Height of the chunk
 * @Ret:    Chunk generated
 */
Chunk generate_chunk(GenerationEngine engine, GenerationChunk chunk_abs, Coords player_entry, Coords prechunk_exit, Coords player_exit, list[VerbAnnotation] verbs_translated) {
    tuple[int,int] chunk_size = <engine.config["chunk_size"].width,engine.config["chunk_size"].height>;
    Chunk chunk_generated = chunk_init(chunk_abs.name, chunk_size);

    chunk_generated = apply_generation_rules(engine, engine.modules[chunk_abs.\module], chunk_generated, player_entry, player_exit, prechunk_exit, verbs_translated);
    
    return chunk_generated;
}

/******************************************************************************/
// --- Private Apply Functions -------------------------------------------------

/*
 * @Name:   apply_generation_rules
 * @Desc:   Function that applies the generation rules associated to each of the 
 *          verbs
 * @Params: engine  -> Generation engine
 *          \module -> Generation module
 *          verbs   -> List of verbs
 *          chunk   -> chunk to generate
 * @Ret:    Generated chunk object
 */
Chunk apply_generation_rules(GenerationEngine engine, GenerationModule \module, Chunk chunk, Coords player_entry, Coords player_exit, Coords prechunk_exit, list[VerbAnnotation] verbs) {
    VerbAnnotation verb_enter = verb_annotation_empty();
    VerbAnnotation verb_exit  = verb_annotation_empty(); 
    tuple[int,int] chunk_size = <engine.config["chunk_size"].width,engine.config["chunk_size"].height>;

    if      (check_entered_above(chunk_size, prechunk_exit)) verb_enter = Annotation::ADT::Verb::enter_down_verb;
    else if (check_entered_below(prechunk_exit))             verb_enter = Annotation::ADT::Verb::enter_up_verb;
    else if (check_entered_left(prechunk_exit))              verb_enter = Annotation::ADT::Verb::enter_right_verb;
    else if (check_entered_right(chunk_size, prechunk_exit)) verb_enter = Annotation::ADT::Verb::enter_left_verb;
    verbs = insertAt(verbs, 0, verb_enter);

    if      (check_exited_up(player_exit))                  verb_exit = Annotation::ADT::Verb::exit_up_verb;
    else if (check_exited_down(chunk_size, player_exit))    verb_exit = Annotation::ADT::Verb::exit_down_verb;
    else if (check_exited_right(chunk_size, player_exit))   verb_exit = Annotation::ADT::Verb::exit_right_verb;
    else if (check_exited_left(player_exit))                verb_exit = Annotation::ADT::Verb::exit_left_verb;
    if (!verb_exit is verb_annotation_empty) verbs += [verb_exit];

    for (VerbAnnotation verb <- verbs[0..(size(verbs))]) {
        GenerationRule rule = \module.generation_rules[verb];
        GenerationPattern left = engine.patterns[rule.left];
        GenerationPattern right = engine.patterns[rule.right];
        chunk = apply_generation_rule(verb, left, right, chunk, player_entry);
    }

    println(chunk.name);
    println(chunk_to_string(chunk));
    println();

    return chunk;
}

/*
 * @Name:   generate_chunk
 * @Desc:   Function that applies the generation one rule
 * @Params: verb  -> Verb to apply
 *          left  -> LHS of the generation rule
 *          right -> RHS of the generation rule
 *          chunk -> Chunk to generate
 * @Ret:    Generated chunk object
 */
Chunk apply_generation_rule(VerbAnnotation verb, GenerationPattern left, GenerationPattern right, Chunk chunk, Coords player_entry) {
    str program = "";

    program = match_generate_program(chunk, player_entry, verb, left, right);
    if(result(Chunk chunk_rewritten) := eval(program)) {
        chunk = chunk_rewritten;
    }

    return chunk;
}

Chunk apply_place_player(Chunk chunk, Coords player_entry) {
    chunk.objects[chunk.size.width * player_entry.y + player_entry.x] = "p";
    return chunk;
}

/*
 * @Name:   apply_blanketize
 * @Desc:   Function that eliminates those 
 * @Params: engine -> Generation engine
 *          chunk  -> Chunk to generate
 * @Ret:    Generated chunk object
 */
Chunk apply_blanketize(GenerationEngine engine, Chunk chunk) {
    for(int i <- [0..size(chunk.objects)]) {
        if (chunk.objects[i] notin engine.config["objects_permanent"].objects) chunk.objects[i] = ".";
    }

    return chunk;
}

/*
 * @Name:   apply_merge
 * @Desc:   Function that merges two chunks
 * @Params: name                 -> Name of the chunk
 *          main_chunk_generated  -> Chunk containing the win playtrace
 *          alt_chunk_generated -> Chunk containing the challenge playtrace
 * @Ret:    Merged chunk object
 */
Chunk apply_merge(str name, Chunk main_chunk_generated, Chunk alt_chunk_generated) {
    list[str] objects_merged = [];

    if      (alt_chunk_generated is chunk_empty) return main_chunk_generated;
    else if (main_chunk_generated       is chunk_empty) return alt_chunk_generated;

    for (int i <- [0..size(main_chunk_generated.objects)]) {
        if      (main_chunk_generated.objects[i] != "." && alt_chunk_generated.objects[i] == ".")     objects_merged += [main_chunk_generated.objects[i]];
        else if (main_chunk_generated.objects[i] == "." && alt_chunk_generated.objects[i] != ".")     objects_merged += [alt_chunk_generated.objects[i]];
        else if (main_chunk_generated.objects[i] != "." && alt_chunk_generated.objects[i] != ".") {
            if      (main_chunk_generated.objects[i] != "#" && alt_chunk_generated.objects[i] == "#") objects_merged += [main_chunk_generated.objects[i]];
            else if (main_chunk_generated.objects[i] == "#" && alt_chunk_generated.objects[i] != "#") objects_merged += [challenge_chunk_generated.objects[i]];
            else                                                                                      objects_merged += [main_chunk_generated.objects[i]];
        }
        else                                                                                      objects_merged += [main_chunk_generated.objects[i]];
    }

    return chunk(name, main_chunk_generated.size, objects_merged);
}