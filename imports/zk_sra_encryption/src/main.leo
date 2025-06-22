program zk_sra_encryption.aleo {
    function exp_by_squaring(base: u128, exp: u128, modulus: u128) -> u128 {
        let result: u128 = 1u128;
        let current_base: u128 = base;

        for i: u8 in 0u8..8u8 {
            if (exp % 2u128 == 1u128) { 
                result = (result * current_base) % modulus;
            }
            current_base = (current_base * current_base) % modulus;
            exp >>= 1u8; // divide by two
        }

        return result as u128;
    }
    
    transition encrypt_deck(e: u128, n: u128, deck: [[u128; 14]; 2]) -> [[u128; 14]; 2] {
        let bottom_half: [u128; 14] = deck[0u8];
        let top_half: [u128; 14] = deck[1u8];
        
        let encrypted_deck: [[u128; 14]; 2] = [
            [
                exp_by_squaring(bottom_half[0u8], e, n),
                exp_by_squaring(bottom_half[1u8], e, n),
                exp_by_squaring(bottom_half[2u8], e, n),
                exp_by_squaring(bottom_half[3u8], e, n),
                exp_by_squaring(bottom_half[4u8], e, n),
                exp_by_squaring(bottom_half[5u8], e, n),
                exp_by_squaring(bottom_half[6u8], e, n),
                exp_by_squaring(bottom_half[7u8], e, n),
                exp_by_squaring(bottom_half[8u8], e, n),
                exp_by_squaring(bottom_half[9u8], e, n),
                exp_by_squaring(bottom_half[10u8], e, n),
                exp_by_squaring(bottom_half[11u8], e, n),
                exp_by_squaring(bottom_half[12u8], e, n),
                exp_by_squaring(bottom_half[13u8], e, n)
            ],
            [
                exp_by_squaring(top_half[0u8], e, n),
                exp_by_squaring(top_half[1u8], e, n),
                exp_by_squaring(top_half[2u8], e, n),
                exp_by_squaring(top_half[3u8], e, n),
                exp_by_squaring(top_half[4u8], e, n),
                exp_by_squaring(top_half[5u8], e, n),
                exp_by_squaring(top_half[6u8], e, n),
                exp_by_squaring(top_half[7u8], e, n),
                exp_by_squaring(top_half[8u8], e, n),
                exp_by_squaring(top_half[9u8], e, n),
                exp_by_squaring(top_half[10u8], e, n),
                exp_by_squaring(top_half[11u8], e, n),
                exp_by_squaring(top_half[12u8], e, n),
                exp_by_squaring(top_half[13u8], e, n)
            ]
        ];
        
        return encrypted_deck;
    }


    transition decrypt_card(d: u128, n: u128, card: u128) -> u128 {
        return exp_by_squaring(card, d, n);
    }

    transition test_encrypt_exp_by_squaring(public m: u128, e: u128, d: u128, n: u128) -> (u128, u128) {
      let c: u128 = exp_by_squaring(m, e, n);
      let p: u128 = exp_by_squaring(c, d, n);
      assert_eq(m, p);
      return (c, p);
    }

    transition test_exp_by_squaring(public m: u128, d1: u128, d2: u128, n: u128) -> (u128, u128) {
      let m1: u128 = exp_by_squaring(m, d1, n);
      let p: u128 = exp_by_squaring(m1, d2, n);
      return (m1, p);
    }
}
