use starknet::ContractAddress;
use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use dojo_game::models::{Game, Board};

#[dojo::interface]
trait IActions {
    fn create_game(ref world: IWorldDispatcher, player_two: ContractAddress) -> u32;
    fn make_move(ref world: IWorldDispatcher, game_id: u32, position: u8);
}

#[dojo::contract]
mod actions {
    use super::{IActions, Game, Board};
    use starknet::{ContractAddress, get_caller_address};
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

    #[abi(embed_v0)]
    impl ActionsImpl of IActions<ContractState> {
        fn create_game(ref world: IWorldDispatcher, player_two: ContractAddress) -> u32 {
            let player_one = get_caller_address();
            let game_id = world.uuid();

            // Initialize game
            set!(
                world,
                (
                    Game {
                        game_id,
                        player_one,
                        player_two,
                        winner: 0,
                        current_turn: 1,
                        is_active: true,
                    },
                    Board { game_id, cells: 0 }
                )
            );

            game_id
        }

        fn make_move(ref world: IWorldDispatcher, game_id: u32, position: u8) {
            let caller = get_caller_address();
            
            // Get game state
            let mut game: Game = get!(world, game_id, (Game));
            let mut board: Board = get!(world, game_id, (Board));

            // Validate game is active
            assert(game.is_active, 'Game is not active');
            
            // Validate position (0-8)
            assert(position < 9, 'Invalid position');

            // Validate it's the caller's turn
            let player_mark = if caller == game.player_one {
                assert(game.current_turn == 1, 'Not your turn');
                1
            } else if caller == game.player_two {
                assert(game.current_turn == 2, 'Not your turn');
                2
            } else {
                panic!("Not a player in this game")
            };

            // Check if position is empty
            let cell_value = get_cell(board.cells, position);
            assert(cell_value == 0, 'Position already taken');

            // Make the move
            board.cells = set_cell(board.cells, position, player_mark);

            // Check for winner
            let winner = check_winner(board.cells);
            if winner != 0 {
                game.winner = winner;
                game.is_active = false;
            } else if is_board_full(board.cells) {
                game.winner = 3; // Draw
                game.is_active = false;
            } else {
                // Switch turn
                game.current_turn = if game.current_turn == 1 { 2 } else { 1 };
            }

            // Update state
            set!(world, (game, board));
        }
    }

    // Helper functions
    fn get_cell(cells: felt252, position: u8) -> u8 {
        let cells_u256: u256 = cells.into();
        let shift = position.into() * 2;
        let mask: u256 = 3;
        ((cells_u256 / pow(2, shift)) & mask).try_into().unwrap()
    }

    fn set_cell(cells: felt252, position: u8, value: u8) -> felt252 {
        let cells_u256: u256 = cells.into();
        let shift = position.into() * 2;
        let mask: u256 = 3;
        let cleared = cells_u256 & ~(mask * pow(2, shift));
        let value_u256: u256 = value.into();
        (cleared + (value_u256 * pow(2, shift))).try_into().unwrap()
    }

    fn pow(base: u256, exp: u256) -> u256 {
        // Iterative approach for power of 2
        if base == 2 {
            // Use bit shifting for powers of 2
            let mut result: u256 = 1;
            let mut i: u256 = 0;
            loop {
                if i >= exp {
                    break result;
                }
                result = result * 2;
                i += 1;
            }
        } else {
            // General case - iterative
            let mut result: u256 = 1;
            let mut i: u256 = 0;
            loop {
                if i >= exp {
                    break result;
                }
                result = result * base;
                i += 1;
            }
        }
    }

    fn check_winner(cells: felt252) -> u8 {
        // Winning combinations (rows, columns, diagonals)
        let winning_lines = array![
            array![0, 1, 2], // Top row
            array![3, 4, 5], // Middle row
            array![6, 7, 8], // Bottom row
            array![0, 3, 6], // Left column
            array![1, 4, 7], // Middle column
            array![2, 5, 8], // Right column
            array![0, 4, 8], // Diagonal
            array![2, 4, 6], // Anti-diagonal
        ];

        let mut i = 0;
        loop {
            if i >= winning_lines.len() {
                break 0;
            }

            let line = winning_lines.at(i);
            let a = get_cell(cells, *line.at(0));
            let b = get_cell(cells, *line.at(1));
            let c = get_cell(cells, *line.at(2));

            if a != 0 && a == b && b == c {
                break a;
            }

            i += 1;
        }
    }

    fn is_board_full(cells: felt252) -> bool {
        let mut i = 0;
        loop {
            if i >= 9 {
                break true;
            }
            if get_cell(cells, i) == 0 {
                break false;
            }
            i += 1;
        }
    }
}
