import zk_deck_shuffle.aleo;
import zk_sra_encryption.aleo;

program war.aleo {

    mapping games: u32 => Game;

    inline get_new_deck() -> [[u128; 26]; 2] {
        return [[1u128, 2u128, 3u128, 4u128, 5u128, 6u128, 7u128, 8u128, 9u128, 10u128, 11u128, 12u128, 13u128, 14u128, 15u128, 16u128, 17u128, 18u128, 19u128, 20u128, 21u128, 22u128, 23u128, 24u128, 25u128, 26u128],
                [27u128, 28u128, 29u128, 30u128, 31u128, 32u128, 33u128, 34u128, 35u128, 36u128, 37u128, 38u128, 39u128, 40u128, 41u128, 42u128, 43u128, 44u128, 45u128, 46u128, 47u128, 48u128, 49u128, 50u128, 51u128, 52u128]];
    }
    inline assert_all_revealed(game: Game) {
        assert(game.p1_must_reveal_p1 == false);
        assert(game.p1_must_reveal_p2 == false);
        assert(game.p2_must_reveal_p1 == false);
        assert(game.p2_must_reveal_p2 == false);
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

        p1_must_reveal_p1: bool,
        p1_must_reveal_p2: bool,
        
        p2_must_reveal_p1: bool,
        p2_must_reveal_p2: bool,
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

            p1_must_reveal_p1: false,
            p1_must_reveal_p2: false,

            p2_must_reveal_p1: false,
            p2_must_reveal_p2: false,
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
            player2: game.player2,
            cards_p1: new_deck[0],
            cards_p2: new_deck[1],
            chips_p1: game.chips_p1,
            chips_p2: game.chips_p2,
            turn: 1u8,
            remaining_cards_p1: game.remaining_cards_p1,
            remaining_cards_p2: game.remaining_cards_p2,

            p1_must_reveal_p1: false,
            p1_must_reveal_p2: true,

            p2_must_reveal_p1: false,
            p2_must_reveal_p2: true,
        };
        
        Mapping::set(games, game_id, new_game);
    }


    // Player 2 is able to see the top card of his deck after this.
    async transition p1_reveal_p2(game_id: u32, card_encrypted: u128, keys: Keys) -> (Keys, Future) {
        let card_decrypted: u128 = zk_sra_encryption.aleo/decrypt_card(keys.d, keys.n, card_encrypted);
        let caller = self.caller;
        return (keys, finalize_p1_reveal_p2(game_id, caller, card_encrypted, card_decrypted));
    }
    async function finalize_p1_reveal_p2(game_id: u32, caller: address, card_encrypted: u128, card_decrypted: u128) {
        let game: Game = Mapping::get(games, game_id);

        let card_to_decrypt: u128 = (game.remaining_cards_p1 == 26u8) ? game.cards_p1[25u8] : 
                                     (game.remaining_cards_p1 == 25u8) ? game.cards_p1[24u8] :
                                     (game.remaining_cards_p1 == 24u8) ? game.cards_p1[23u8] :
                                     (game.remaining_cards_p1 == 23u8) ? game.cards_p1[22u8] :
                                     (game.remaining_cards_p1 == 22u8) ? game.cards_p1[21u8] :
                                     (game.remaining_cards_p1 == 21u8) ? game.cards_p1[20u8] :
                                     (game.remaining_cards_p1 == 20u8) ? game.cards_p1[19u8] :
                                     (game.remaining_cards_p1 == 19u8) ? game.cards_p1[18u8] :
                                     (game.remaining_cards_p1 == 18u8) ? game.cards_p1[17u8] :
                                     (game.remaining_cards_p1 == 17u8) ? game.cards_p1[16u8] :
                                     (game.remaining_cards_p1 == 16u8) ? game.cards_p1[15u8] :
                                     (game.remaining_cards_p1 == 15u8) ? game.cards_p1[14u8] :
                                     (game.remaining_cards_p1 == 14u8) ? game.cards_p1[13u8] :
                                     (game.remaining_cards_p1 == 13u8) ? game.cards_p1[12u8] :
                                     (game.remaining_cards_p1 == 12u8) ? game.cards_p1[11u8] :
                                     (game.remaining_cards_p1 == 11u8) ? game.cards_p1[10u8] :
                                     (game.remaining_cards_p1 == 10u8) ? game.cards_p1[9u8] :
                                     (game.remaining_cards_p1 == 9u8) ? game.cards_p1[8u8] :
                                     (game.remaining_cards_p1 == 8u8) ? game.cards_p1[7u8] :
                                     (game.remaining_cards_p1 == 7u8) ? game.cards_p1[6u8] :
                                     (game.remaining_cards_p1 == 6u8) ? game.cards_p1[5u8] :
                                     (game.remaining_cards_p1 == 5u8) ? game.cards_p1[4u8] :
                                     (game.remaining_cards_p1 == 4u8) ? game.cards_p1[3u8] :
                                     (game.remaining_cards_p1 == 3u8) ? game.cards_p1[2u8] :
                                     (game.remaining_cards_p1 == 2u8) ? game.cards_p1[1u8] :
                                     game.cards_p1[0u8];

        assert(caller == game.player1);
        assert(card_encrypted == card_to_decrypt);
        assert(game.p1_must_reveal_p1 == true);

        let new_cards_p1: [u128; 26] = [
            (game.remaining_cards_p1 == 1u8) ? card_decrypted : game.cards_p1[0u8],
            (game.remaining_cards_p1 == 2u8) ? card_decrypted : game.cards_p1[1u8],
            (game.remaining_cards_p1 == 3u8) ? card_decrypted : game.cards_p1[2u8],
            (game.remaining_cards_p1 == 4u8) ? card_decrypted : game.cards_p1[3u8],
            (game.remaining_cards_p1 == 5u8) ? card_decrypted : game.cards_p1[4u8],
            (game.remaining_cards_p1 == 6u8) ? card_decrypted : game.cards_p1[5u8],
            (game.remaining_cards_p1 == 7u8) ? card_decrypted : game.cards_p1[6u8],
            (game.remaining_cards_p1 == 8u8) ? card_decrypted : game.cards_p1[7u8],
            (game.remaining_cards_p1 == 9u8) ? card_decrypted : game.cards_p1[8u8],
            (game.remaining_cards_p1 == 10u8) ? card_decrypted : game.cards_p1[9u8],
            (game.remaining_cards_p1 == 11u8) ? card_decrypted : game.cards_p1[10u8],
            (game.remaining_cards_p1 == 12u8) ? card_decrypted : game.cards_p1[11u8],
            (game.remaining_cards_p1 == 13u8) ? card_decrypted : game.cards_p1[12u8],
            (game.remaining_cards_p1 == 14u8) ? card_decrypted : game.cards_p1[13u8],
            (game.remaining_cards_p1 == 15u8) ? card_decrypted : game.cards_p1[14u8],
            (game.remaining_cards_p1 == 16u8) ? card_decrypted : game.cards_p1[15u8],
            (game.remaining_cards_p1 == 17u8) ? card_decrypted : game.cards_p1[16u8],
            (game.remaining_cards_p1 == 18u8) ? card_decrypted : game.cards_p1[17u8],
            (game.remaining_cards_p1 == 19u8) ? card_decrypted : game.cards_p1[18u8],
            (game.remaining_cards_p1 == 20u8) ? card_decrypted : game.cards_p1[19u8],
            (game.remaining_cards_p1 == 21u8) ? card_decrypted : game.cards_p1[20u8],
            (game.remaining_cards_p1 == 22u8) ? card_decrypted : game.cards_p1[21u8],
            (game.remaining_cards_p1 == 23u8) ? card_decrypted : game.cards_p1[22u8],
            (game.remaining_cards_p1 == 24u8) ? card_decrypted : game.cards_p1[23u8],
            (game.remaining_cards_p1 == 25u8) ? card_decrypted : game.cards_p1[24u8],
            (game.remaining_cards_p1 == 26u8) ? card_decrypted : game.cards_p1[25u8]
        ];

        let new_game: Game = Game {
            player1: game.player1,
            player2: game.player2,
            cards_p1: new_cards_p1,
            cards_p2: game.cards_p2,
            chips_p1: game.chips_p1,
            chips_p2: game.chips_p2,
            turn: game.turn,
            remaining_cards_p1: game.remaining_cards_p1,
            remaining_cards_p2: game.remaining_cards_p2,

            p1_must_reveal_p1: false,
            p1_must_reveal_p2: game.p1_must_reveal_p2,

            p2_must_reveal_p1: game.p2_must_reveal_p1,
            p2_must_reveal_p2: game.p2_must_reveal_p2,
        };
        Mapping::set(games, game_id, new_game);
    }



    async transition p1_reveal_p1(game_id: u32, card_encrypted: u128, keys: Keys) -> (Keys, Future) {
        let card_decrypted: u128 = zk_sra_encryption.aleo/decrypt_card(keys.d, keys.n, card_encrypted);
        let caller = self.caller;
        return (keys, finalize_p1_reveal_p1(game_id, caller, card_encrypted, card_decrypted));
    }
    async function finalize_p1_reveal_p1(game_id: u32, caller: address, card_encrypted: u128, card_decrypted: u128) {
        let game: Game = Mapping::get(games, game_id);

        let card_to_decrypt: u128 = (game.remaining_cards_p1 == 26u8) ? game.cards_p1[25u8] : 
                                     (game.remaining_cards_p1 == 25u8) ? game.cards_p1[24u8] :
                                     (game.remaining_cards_p1 == 24u8) ? game.cards_p1[23u8] :
                                     (game.remaining_cards_p1 == 23u8) ? game.cards_p1[22u8] :
                                     (game.remaining_cards_p1 == 22u8) ? game.cards_p1[21u8] :
                                     (game.remaining_cards_p1 == 21u8) ? game.cards_p1[20u8] :
                                     (game.remaining_cards_p1 == 20u8) ? game.cards_p1[19u8] :
                                     (game.remaining_cards_p1 == 19u8) ? game.cards_p1[18u8] :
                                     (game.remaining_cards_p1 == 18u8) ? game.cards_p1[17u8] :
                                     (game.remaining_cards_p1 == 17u8) ? game.cards_p1[16u8] :
                                     (game.remaining_cards_p1 == 16u8) ? game.cards_p1[15u8] :
                                     (game.remaining_cards_p1 == 15u8) ? game.cards_p1[14u8] :
                                     (game.remaining_cards_p1 == 14u8) ? game.cards_p1[13u8] :
                                     (game.remaining_cards_p1 == 13u8) ? game.cards_p1[12u8] :
                                     (game.remaining_cards_p1 == 12u8) ? game.cards_p1[11u8] :
                                     (game.remaining_cards_p1 == 11u8) ? game.cards_p1[10u8] :
                                     (game.remaining_cards_p1 == 10u8) ? game.cards_p1[9u8] :
                                     (game.remaining_cards_p1 == 9u8) ? game.cards_p1[8u8] :
                                     (game.remaining_cards_p1 == 8u8) ? game.cards_p1[7u8] :
                                     (game.remaining_cards_p1 == 7u8) ? game.cards_p1[6u8] :
                                     (game.remaining_cards_p1 == 6u8) ? game.cards_p1[5u8] :
                                     (game.remaining_cards_p1 == 5u8) ? game.cards_p1[4u8] :
                                     (game.remaining_cards_p1 == 4u8) ? game.cards_p1[3u8] :
                                     (game.remaining_cards_p1 == 3u8) ? game.cards_p1[2u8] :
                                     (game.remaining_cards_p1 == 2u8) ? game.cards_p1[1u8] :
                                     game.cards_p1[0u8];

        assert(caller == game.player1);
        assert(card_encrypted == card_to_decrypt);
        assert(game.p1_must_reveal_p1 == true);

        let new_cards_p1: [u128; 26] = [
            (game.remaining_cards_p1 == 1u8) ? card_decrypted : game.cards_p1[0u8],
            (game.remaining_cards_p1 == 2u8) ? card_decrypted : game.cards_p1[1u8],
            (game.remaining_cards_p1 == 3u8) ? card_decrypted : game.cards_p1[2u8],
            (game.remaining_cards_p1 == 4u8) ? card_decrypted : game.cards_p1[3u8],
            (game.remaining_cards_p1 == 5u8) ? card_decrypted : game.cards_p1[4u8],
            (game.remaining_cards_p1 == 6u8) ? card_decrypted : game.cards_p1[5u8],
            (game.remaining_cards_p1 == 7u8) ? card_decrypted : game.cards_p1[6u8],
            (game.remaining_cards_p1 == 8u8) ? card_decrypted : game.cards_p1[7u8],
            (game.remaining_cards_p1 == 9u8) ? card_decrypted : game.cards_p1[8u8],
            (game.remaining_cards_p1 == 10u8) ? card_decrypted : game.cards_p1[9u8],
            (game.remaining_cards_p1 == 11u8) ? card_decrypted : game.cards_p1[10u8],
            (game.remaining_cards_p1 == 12u8) ? card_decrypted : game.cards_p1[11u8],
            (game.remaining_cards_p1 == 13u8) ? card_decrypted : game.cards_p1[12u8],
            (game.remaining_cards_p1 == 14u8) ? card_decrypted : game.cards_p1[13u8],
            (game.remaining_cards_p1 == 15u8) ? card_decrypted : game.cards_p1[14u8],
            (game.remaining_cards_p1 == 16u8) ? card_decrypted : game.cards_p1[15u8],
            (game.remaining_cards_p1 == 17u8) ? card_decrypted : game.cards_p1[16u8],
            (game.remaining_cards_p1 == 18u8) ? card_decrypted : game.cards_p1[17u8],
            (game.remaining_cards_p1 == 19u8) ? card_decrypted : game.cards_p1[18u8],
            (game.remaining_cards_p1 == 20u8) ? card_decrypted : game.cards_p1[19u8],
            (game.remaining_cards_p1 == 21u8) ? card_decrypted : game.cards_p1[20u8],
            (game.remaining_cards_p1 == 22u8) ? card_decrypted : game.cards_p1[21u8],
            (game.remaining_cards_p1 == 23u8) ? card_decrypted : game.cards_p1[22u8],
            (game.remaining_cards_p1 == 24u8) ? card_decrypted : game.cards_p1[23u8],
            (game.remaining_cards_p1 == 25u8) ? card_decrypted : game.cards_p1[24u8],
            (game.remaining_cards_p1 == 26u8) ? card_decrypted : game.cards_p1[25u8]
        ];

        let new_game: Game = Game {
            player1: game.player1,
            player2: game.player2,
            cards_p1: new_cards_p1,
            cards_p2: game.cards_p2,
            chips_p1: game.chips_p1,
            chips_p2: game.chips_p2,
            turn: game.turn,
            remaining_cards_p1: game.remaining_cards_p1,
            remaining_cards_p2: game.remaining_cards_p2,

            p1_must_reveal_p1: false,
            p1_must_reveal_p2: game.p1_must_reveal_p2,

            p2_must_reveal_p1: game.p2_must_reveal_p1,
            p2_must_reveal_p2: game.p2_must_reveal_p2,
        };
        Mapping::set(games, game_id, new_game);
    }
}
