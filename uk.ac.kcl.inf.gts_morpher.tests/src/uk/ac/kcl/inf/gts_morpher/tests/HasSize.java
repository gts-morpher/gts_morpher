package uk.ac.kcl.inf.gts_morpher.tests;

import java.lang.reflect.InvocationTargetException;

import org.hamcrest.Description;
import org.hamcrest.Factory;
import org.hamcrest.Matcher;
import org.hamcrest.TypeSafeMatcher;

/* Matches any class that has a <code>size()</code> method
 * that returns an <code>int</code> */ 
public class HasSize<T> extends TypeSafeMatcher<T>
{
    @Factory
    public static <T> Matcher<T> hasSize(int val)
    {
        return new HasSize<T>(val);
    }
    
    private int val;
    
    private HasSize(int val) {
    	this.val = val;
    }

    @Override
    protected boolean matchesSafely(final T item)
    {
        try { return ((int) item.getClass().getMethod("size", (Class<?>[]) null).invoke(item) == val); }
        catch (final NoSuchMethodException e) { return false; }
        catch (final InvocationTargetException | IllegalAccessException e) { throw new RuntimeException(e); }
    }

    @Override
    public void describeTo(final Description description) { description.appendText("is of size " + val); }
}