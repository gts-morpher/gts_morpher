package uk.ac.kcl.inf.tests

import org.junit.runner.RunWith
import org.junit.runners.Suite
import uk.ac.kcl.inf.tests.composer.ComposerTests
import uk.ac.kcl.inf.tests.syntax.ParsingAndValidationTests

@RunWith(Suite)
@Suite.SuiteClasses(
  ParsingAndValidationTests,
  ComposerTests
)
//@InjectWith(XDsmlComposeInjectorProvider)
// FIXME: This causes the composer tests to crash with an ExceptionInitializerError...
class TestSuite {
}