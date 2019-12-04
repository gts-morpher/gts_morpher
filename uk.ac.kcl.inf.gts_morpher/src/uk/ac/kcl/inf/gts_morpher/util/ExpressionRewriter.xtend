package uk.ac.kcl.inf.gts_morpher.util

import org.eclipse.emf.henshin.model.Parameter

/**
 * Helper class for rewriting expressions in the presence of changes to rule-parameter names.
 */
class ExpressionRewriter {
	static def String matchParamRegexp(Parameter srcParam) '''(^|[^_a-zA-Z])«srcParam.name»([^_a-zA-Z0-9]|$)'''

	static def String replacementExpression(Parameter tgtParam) '''$1«tgtParam.name»$2'''

	static def String rewrittenExpression(String srcExpression, Parameter srcParam, Parameter tgtParam) {
		val replacement = tgtParam.replacementExpression
		
		srcExpression.rewrittenExpression(srcParam, replacement)
	}
	
	static def String rewrittenExpression(String srcExpression, Parameter srcParam, String tgtParamReplacementExpression) {
		val regexp = srcParam.matchParamRegexp
		
		srcExpression.replaceAll(regexp, tgtParamReplacementExpression)		
	}
}
