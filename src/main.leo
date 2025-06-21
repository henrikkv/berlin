import zk_deck_shuffle.aleo;
import zk_sra_encryption.aleo;

program war.aleo {

    mapping games: u32 => Game;

    inline get_new_deck() -> [[u128; 26]; 2] {
        return [[1u128, 2u128, 3u128, 4u128, 5u128, 6u128, 7u128, 8u128, 9u128, 10u128, 11u128, 12u128, 13u128, 14u128, 15u128, 16u128, 17u128, 18u128, 19u128, 20u128, 21u128, 22u128, 23u128, 24u128, 25u128, 26u128],
                [27u128, 28u128, 29u128, 30u128, 31u128, 32u128, 33u128, 34u128, 35u128, 36u128, 37u128, 38u128, 39u128, 40u128, 41u128, 42u128, 43u128, 44u128, 45u128, 46u128, 47u128, 48u128, 49u128, 50u128, 51u128, 52u128]];
    }
    record Keys {
        owner: address,
        e: u128,
        d: u128,
        n: u128,
    }
    struct Game {
        player1: address,
        player2: address,
        cards_p1: [u128; 26],
        cards_p2: [u128; 26],
        chips_p1: u8,
        chips_p2: u8,
        turn: u8, // Increases every transaction
        remaining_cards_p1: u8, // Cards with index lower than this number are still encrypted
        remaining_cards_p2: u8,
    }



    async transition create_game(game_id: u32, element1: i8, element2: i8, element3: i8, e: u128, d: u128, n: u128) -> (Keys, Future) {
        let deck: [[u128; 26]; 2] = zk_deck_shuffle.aleo/full_shuffle(element1, element2, element3, zk_sra_encryption.aleo/encrypt_deck(e, n, get_new_deck()));
        let keys: Keys = Keys {
            owner: self.caller,
            e: e,
            d: d,
            n: n,
        };
        return (keys, finalize_create_game(game_id, deck, self.caller));
    }
    async function finalize_create_game(game_id: u32, deck: [[u128; 26]; 2], caller: address) {
        let game: Game = Game {
            player1: caller,
            player2: 0u128 as address,
            cards_p1: deck[0],
            cards_p2: deck[1],
            chips_p1: 32u8,
            chips_p2: 32u8,
            turn: 0u8,
            remaining_cards_p1: 26u8,
            remaining_cards_p2: 26u8,
        };
        Mapping::set(games, game_id, game);
    }



    async transition join_game(game_id: u32, deck: [[u128; 26]; 2], element1: i8, element2: i8, element3: i8, e: u128, d: u128, n: u128) -> (Keys, Future) {
        let new_deck: [[u128; 26]; 2] = zk_deck_shuffle.aleo/full_shuffle(element1, element2, element3, zk_sra_encryption.aleo/encrypt_deck(e, n, deck)); 
        let keys: Keys = Keys {
            owner: self.caller,
            e: e,
            d: d,
            n: n,
        };
        return (keys, finalize_join_game(game_id, deck, new_deck, self.caller));
    }
    async function finalize_join_game(game_id: u32, deck: [[u128; 26]; 2], new_deck: [[u128; 26]; 2], caller: address) {
        let game: Game = Mapping::get(games, game_id);    
        assert(game.cards_p1 == deck[0]);
        assert(game.cards_p2 == deck[1]);
        
        let new_game: Game = Game {
            player1: game.player1,
            player2: caller,
            cards_p1: new_deck[0],
            cards_p2: new_deck[1],
            chips_p1: game.chips_p1,
            chips_p2: game.chips_p2,
            turn: 1u8,
            remaining_cards_p1: game.remaining_cards_p1,
            remaining_cards_p2: game.remaining_cards_p2,
        };
        
        Mapping::set(games, game_id, new_game);
    }
}
