import zk_deck_shuffle.aleo;
import zk_sra_encryption.aleo;
program war.aleo;

record Keys:
    owner as address.private;
    e as u128.private;
    d as u128.private;
    n as u128.private;

struct Game:
    player1 as address;
    player2 as address;
    cards_p1 as [u128; 26u32];
    cards_p2 as [u128; 26u32];
    chips_p1 as u8;
    chips_p2 as u8;
    turn as u8;
    remaining_cards_p1 as u8;
    remaining_cards_p2 as u8;

mapping games:
    key as u32.public;
    value as Game.public;

function create_game:
    input r0 as u32.private;
    input r1 as i8.private;
    input r2 as i8.private;
    input r3 as i8.private;
    input r4 as u128.private;
    input r5 as u128.private;
    input r6 as u128.private;
    cast 1u128 2u128 3u128 4u128 5u128 6u128 7u128 8u128 9u128 10u128 11u128 12u128 13u128 14u128 15u128 16u128 17u128 18u128 19u128 20u128 21u128 22u128 23u128 24u128 25u128 26u128 into r7 as [u128; 26u32];
    cast 27u128 28u128 29u128 30u128 31u128 32u128 33u128 34u128 35u128 36u128 37u128 38u128 39u128 40u128 41u128 42u128 43u128 44u128 45u128 46u128 47u128 48u128 49u128 50u128 51u128 52u128 into r8 as [u128; 26u32];
    cast r7 r8 into r9 as [[u128; 26u32]; 2u32];
    call zk_sra_encryption.aleo/encrypt_deck r4 r6 r9 into r10;
    call zk_deck_shuffle.aleo/full_shuffle r1 r2 r3 r10 into r11;
    cast self.caller r4 r5 r6 into r12 as Keys.record;
    async create_game r0 r11 self.caller into r13;
    output r12 as Keys.record;
    output r13 as war.aleo/create_game.future;

finalize create_game:
    input r0 as u32.public;
    input r1 as [[u128; 26u32]; 2u32].public;
    input r2 as address.public;
    cast r2 aleo1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq3ljyzc r1[0u32] r1[1u32] 32u8 32u8 0u8 26u8 26u8 into r3 as Game;
    set r3 into games[r0];

function join_game:
    input r0 as u32.private;
    input r1 as [[u128; 26u32]; 2u32].private;
    input r2 as i8.private;
    input r3 as i8.private;
    input r4 as i8.private;
    input r5 as u128.private;
    input r6 as u128.private;
    input r7 as u128.private;
    call zk_sra_encryption.aleo/encrypt_deck r5 r7 r1 into r8;
    call zk_deck_shuffle.aleo/full_shuffle r2 r3 r4 r8 into r9;
    cast self.caller r5 r6 r7 into r10 as Keys.record;
    async join_game r0 r1 r9 self.caller into r11;
    output r10 as Keys.record;
    output r11 as war.aleo/join_game.future;

finalize join_game:
    input r0 as u32.public;
    input r1 as [[u128; 26u32]; 2u32].public;
    input r2 as [[u128; 26u32]; 2u32].public;
    input r3 as address.public;
    get games[r0] into r4;
    is.eq r4.cards_p1 r1[0u32] into r5;
    assert.eq r5 true;
    is.eq r4.cards_p2 r1[1u32] into r6;
    assert.eq r6 true;
    cast r4.player1 r3 r2[0u32] r2[1u32] r4.chips_p1 r4.chips_p2 1u8 r4.remaining_cards_p1 r4.remaining_cards_p2 into r7 as Game;
    set r7 into games[r0];
