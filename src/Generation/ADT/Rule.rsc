/*
 * @Module: Rule
 * @Desc:   Module that contains the functionality for the generation rule
 * @Auth:   Borja Velasco -> code, comments
 */
module Generation::ADT::Rule

/******************************************************************************/
// --- Data structure defines --------------------------------------------------

/*
 * @Name:   GenerationRule
 * @Desc:   Data structure that models a generation rule
 */
data GenerationRule
    = generation_rule(str left, str right)
    | generation_rule_empty()
    ;

/******************************************************************************/
// --- Global implicit generation rule defines ---------------------------------

GenerationRule enter_right_generation_rule = generation_rule("enter_right", "idle_right");
GenerationRule enter_left_generation_rule  = generation_rule("enter_left",  "idle_left");
GenerationRule enter_up_generation_rule    = generation_rule("enter_up",    "idle_up");
GenerationRule enter_down_generation_rule  = generation_rule("enter_down",  "idle_down");
GenerationRule exit_right_generation_rule  = generation_rule("idle_right",  "exit_right");
GenerationRule exit_left_generation_rule   = generation_rule("idle_left",   "exit_left");
GenerationRule exit_up_generation_rule     = generation_rule("idle_up",     "exit_up");
GenerationRule exit_down_generation_rule   = generation_rule("idle_down",   "exit_down");