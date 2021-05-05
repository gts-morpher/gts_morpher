package uk.ac.kcl.inf.gts_morpher.tests;

import org.hamcrest.Description;
import org.hamcrest.Factory;
import org.hamcrest.Matcher;
import org.hamcrest.TypeSafeMatcher;

import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSTraceMember;
import uk.ac.kcl.inf.gts_morpher.modelcaster.GTSTrace;

/* Checks trace equality */ 
public class IsTraceWith extends TypeSafeMatcher<GTSTrace>
{
    @Factory
    public static Matcher<GTSTrace> isTraceWith(GTSTraceMember... members)
    {
        return new IsTraceWith(members);
    }
    
    private GTSTraceMember[] members;
    
    private IsTraceWith(GTSTraceMember... members) {
    	this.members = members;
    }

    @Override
    protected boolean matchesSafely(final GTSTrace item)
    {
        if (item.size() == members.length) {
        	for (int i = 0; i < item.size(); i++) {
        		if (item.get(i) != members[i]) {
        			return false;
        		}
        	}
        	
        	return true;
        } else {
        	return false;
        }
    }

    @Override
    public void describeTo(final Description description) { description.appendText("is trae of " + members); }
}