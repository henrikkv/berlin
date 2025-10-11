use leo_bindings::utils::*;
use leo_bindings_credits::credits::*;
use snarkvm::prelude::Network;
use std::str::FromStr;
use war_bindings::war_game::*;

const ENDPOINT: &str = "http://localhost:3030";
const PRIVATE_KEY: &str = "APrivateKey1zkp8CZNn3yeCseEtxuVPbDCwSyhGW6yZKUYKfgXmcpoGPWH";

#[test]
fn war_testnet() {
    let alice = Account::from_str(PRIVATE_KEY).unwrap();
    run_war_tests(
        &WarGameTestnet::new(&alice, ENDPOINT).unwrap(),
        &CreditsTestnet::new(&alice, ENDPOINT).unwrap(),
        &alice,
    );
}

#[test]
fn war_interpreter() {
    let alice = Account::from_str(PRIVATE_KEY).unwrap();
    run_war_tests(
        &WarGameInterpreter::new(&alice, ENDPOINT).unwrap(),
        &CreditsInterpreter::new(&alice, ENDPOINT).unwrap(),
        &alice,
    );
}

fn run_war_tests<N: Network, W: WarGameAleo<N>, C: CreditsAleo<N>>(
    war: &W,
    credits: &C,
    alice: &Account<N>,
) {
    let rng = &mut rand::thread_rng();
    let bob = Account::new(rng).unwrap();
    credits
        .transfer_public(alice, bob.address(), 1_000_000_000_000)
        .unwrap();

    println!("🎲 Creating war game...");

    let (mut alice_keys, _) = war.create_game(alice, 1, 1, 2, 3, 5, 29, 91).unwrap();
    let game = war.get_games(1).unwrap();

    let deck = [game.cards_p1, game.cards_p2];
    let (mut bob_keys, _) = war.join_game(&bob, 1, deck, 4, 5, 6, 7, 31, 91).unwrap();

    let mut round = 1;
    loop {
        let game = war.get_games(1).unwrap();

        if game.winner != 0 {
            let winner_name = if game.winner == 1 { "Alice" } else { "Bob" };
            println!("\n🏆 GAME OVER! {} wins!", winner_name);
            println!(
                "📈 Final scores - Alice: {} chips | Bob: {} chips",
                game.chips_p1, game.chips_p2
            );
            println!(
                "📦 Remaining cards - Alice: {} | Bob: {}",
                game.remaining_cards_p1, game.remaining_cards_p2
            );
            break;
        }

        println!("\n🚀 Round {} begins!", round);
        println!(
            "💰 Current state - Alice: {} chips | Bob: {} chips",
            game.chips_p1, game.chips_p2
        );
        println!(
            "🃏 Cards remaining - Alice: {} | Bob: {}",
            game.remaining_cards_p1, game.remaining_cards_p2
        );

        dbg!(game);
        println!("💸 Both players bet");
        if game.turn % 2 == 1 {
            war.bet(alice, 1).unwrap();
            war.bet(&bob, 1).unwrap();
        } else {
            war.bet(&bob, 1).unwrap();
            war.bet(alice, 1).unwrap();
        }

        let game = war.get_games(1).unwrap();
        let card_index = (game.remaining_cards_p2 - 1) as usize;
        alice_keys = war
            .p1_reveal_p2(alice, 1, game.cards_p2[card_index], alice_keys)
            .unwrap()
            .0;
        let game = war.get_games(1).unwrap();
        let card_index = (game.remaining_cards_p1 - 1) as usize;
        bob_keys = war
            .p2_reveal_p1(&bob, 1, game.cards_p1[card_index], bob_keys)
            .unwrap()
            .0;

        let game = war.get_games(1).unwrap();
        let card_index = (game.remaining_cards_p1 - 1) as usize;

        alice_keys = war
            .p1_reveal_p1(alice, 1, game.cards_p1[card_index], alice_keys)
            .unwrap()
            .0;
        let game = war.get_games(1).unwrap();
        let card_index = (game.remaining_cards_p2 - 1) as usize;
        bob_keys = war
            .p2_reveal_p2(&bob, 1, game.cards_p2[card_index], bob_keys)
            .unwrap()
            .0;

        war.compare_cards(alice, 1).unwrap();
        let game = war.get_games(1).unwrap();
        let alice_final_card = game.cards_p1[card_index];
        let bob_final_card = game.cards_p2[card_index];
        println!(
            "📊 Alice's card: {} | Bob's card: {}",
            alice_final_card, bob_final_card
        );
        println!(
            "💰 After round: Alice: {} chips | Bob: {} chips",
            game.chips_p1, game.chips_p2
        );
        if game.war > 1 {
            println!("⚔️  WAR continues! Multiplier is now {}", game.war);
        }

        round += 1;
    }
}
