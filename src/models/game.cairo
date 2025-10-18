use starknet::ContractAddress;

#[derive(Model, Copy, Drop, Serde)]
struct Game {
    #[key]
    game_id: u32,
    player_one: ContractAddress,
    player_two: ContractAddress,
    winner: u8, // 0 = no winner, 1 = player_one, 2 = player_two, 3 = draw
    current_turn: u8, // 1 = player_one, 2 = player_two
    is_active: bool,
}

#[derive(Model, Copy, Drop, Serde)]
struct Board {
    #[key]
    game_id: u32,
    cells: felt252, // Packed representation of 9 cells (each cell: 0=empty, 1=X, 2=O)
}
