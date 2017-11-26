package uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.util;

import java.util.AbstractList;
import java.util.List;

import org.eclipse.emf.common.util.EList;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.InternalEObject;
import org.eclipse.emf.ecore.util.DelegatingEcoreEList;

/**
 * A delegating list that translates elements from one type to another.
 * 
 * @author k1074611
 */
@SuppressWarnings("serial")
public class DelegatingTranslatingEcoreEList<S extends EObject, T extends EObject> extends DelegatingEcoreEList<S> {

	/**
	 * Function translating S objects into T objects. It is expected that for the
	 * same S object, always the same T object is provided.
	 * 
	 * @author k1074611
	 *
	 * @param <S>
	 * @param <T>
	 */
	public static interface Translator<S extends EObject, T extends EObject> {
		public S translate(T object);
	}

	protected final int featureID;
	private final EList<T> backingList;
	private List<S> delegateList;
	private final Translator<S, T> translator;

	public DelegatingTranslatingEcoreEList(InternalEObject owner, int featureID, EList<T> backingList,
			Translator<S, T> translator) {
		super(owner);

		this.featureID = featureID;
		this.backingList = backingList;
		this.translator = translator;
	}

	@Override
	public int getFeatureID() {
		return featureID;
	}

	@Override
	protected List<S> delegateList() {
		if (delegateList == null) {
			delegateList = new AbstractList<S>() {

				@Override
				public S get(int index) {
					return translator.translate(backingList.get(index));
				}

				@Override
				public int size() {
					return backingList.size();
				}
			};
		}

		return delegateList;
	}
}