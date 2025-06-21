// The 'test_war' test program.
import war.aleo;
program test_war.aleo {
    @test
    script test_it() {
        let result: u32 = war.aleo/main(1u32, 2u32);
        assert_eq(result, 3u32);
    }

    @test
    @should_fail
    transition do_nothing() {
        let result: u32 = war.aleo/main(2u32, 3u32);
        assert_eq(result, 3u32);
    }
}
