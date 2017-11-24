package uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.util;

import java.util.AbstractList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.eclipse.emf.common.util.EList;
import org.eclipse.emf.ecore.InternalEObject;
import org.eclipse.emf.ecore.util.DelegatingEcoreEList;

/**
 * A delegating list that translates elements from one type to another.
 * 
 * @author k1074611
 */
@SuppressWarnings("serial")
public class DelegatingTranslatingEcoreEList<E, T> extends DelegatingEcoreEList<E> {

	public static interface Translator<E, T> {
		public E translate(T object);
	}

	protected final int featureID;
	private final EList<T> backingList;
	private List<E> delegateList;
	private final Map<T, E> translationCache = new HashMap<>();
	private final Translator<E, T> translator;

	public DelegatingTranslatingEcoreEList(InternalEObject owner, int featureID, EList<T> backingList,
			Translator<E, T> translator) {
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
	protected List<E> delegateList() {
		if (delegateList == null) {
			delegateList = new AbstractList<E>() {

				@Override
				public E get(int index) {
					return translate(backingList.get(index));
				}

				@Override
				public int size() {
					return backingList.size();
				}
			};
		}

		return delegateList;
	}

	private E translate(T object) {
		if (!translationCache.containsKey(object)) {
			translationCache.put(object, translator.translate(object));
		}

		return translationCache.get(object);
	}
}