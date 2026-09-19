package com.bancosol;

import com.intuit.karate.junit5.Karate;

/**
 * JUnit 5 runner for the GoRest users API scenarios.
 * Executes every *.feature file found under the com/bancosol package.
 */
class UsersRunner {

    @Karate.Test
    Karate testUsers() {
        return Karate.run("users").relativeTo(getClass());
    }
}
