package uk.ac.kcl.inf.gts_morpher.tests;

import java.lang.reflect.InvocationTargetException;

import org.hamcrest.Description;
import org.hamcrest.Factory;
import org.hamcrest.Matcher;
import org.hamcrest.TypeSafeMatcher;

/* Matches any class that has an <code>isEmpty()</code> method
 * that returns a <code>boolean</code> */ 
public class IsEmpty<T> extends TypeSafeMatcher<T>
{
    @Factory
    public static <T> Matcher<T> empty()
    {
        return new IsEmpty<T>();
    }

    @Override
    protected boolean matchesSafely(final T item)
    {
        try { return (boolean) item.getClass().getMethod("isEmpty", (Class<?>[]) null).invoke(item); }
        catch (final NoSuchMethodException e) { return false; }
        catch (final InvocationTargetException | IllegalAccessException e) { throw new RuntimeException(e); }
    }

    @Override
    public void describeTo(final Description description) { description.appendText("is empty"); }
}