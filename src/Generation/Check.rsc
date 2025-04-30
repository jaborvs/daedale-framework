/*
 * @Module: Check
 * @Desc:   Module that contains all the functionality to check 
 * @Auth:   Borja Velasco -> code, comments
 */
module Generation::Check

/******************************************************************************/
// --- Own modules imports -----------------------------------------------------
import Utils;

/******************************************************************************/
// --- Check functions ---------------------------------------------------------

bool check_exited_up(Coords player_exit) {
    return player_exit.y == -1 && player_exit.x != -1;
}

bool check_exited_right(tuple[int width, int height] chunk_size, Coords player_exit) {
    return player_exit.x == chunk_size.width;
}

bool check_exited_left(Coords player_exit) {
    return player_exit.x == -1 && player_exit.y != -1;
}

bool check_exited_down(tuple[int width, int height] chunk_size, Coords player_exit) {
    return player_exit.y == chunk_size.height;
}

bool check_entered_above(tuple[int width, int height] chunk_size, Coords prechunk_exit) {
    return  prechunk_exit.y == chunk_size.height;
}

bool check_entered_below(Coords prechunk_exit) {
    return  prechunk_exit.y == -1 && prechunk_exit.x != -1;
}

bool check_entered_left(Coords prechunk_exit) {
    return prechunk_exit.x == -1;
}

bool check_entered_right(tuple[int width, int height] chunk_size, Coords prechunk_exit) {
    return  prechunk_exit.x == chunk_size.width;
}