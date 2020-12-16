#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

workflow {

	Channel
		.fromPath(params.readsDir + params.inputReadsFile) \
		| indexBamFile \
		| configureManta \
		| callVariantsForEachSample \
		| view

}

process indexBamFile {
	container params.samtoolsImage

	input:
	path bamFile

	output:
	tuple path("${bamFile}"), path("${bamFile}.bai")

	script:
	"""
	samtools index ${bamFile}
	"""
}

process configureManta {
	container params.mantaImage

	input:
	tuple path(bamFile), path(bamIndex)

	output:
	path "runDir"

	script:
	"""
	${params.configureManta} \
		--bam ${bamFile} \
		--referenceFasta ${params.referenceSequence['path']} \
		--runDir runDir
	"""
}

process callVariantsForEachSample {
	container params.mantaImage

	input:
	path runDir 

	output:
	stdout

	script:
	"""
	${runDir}/runWorkflow.py \
		-m local \
		-j ${params.nThreadsPerProcess}
	mv -f ${runDir}/results/* ${params.outputDir}/
	"""
}