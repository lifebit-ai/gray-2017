#!/usr/bin/env nextflow
/*
========================================================================================
                         lifebit-ai/pgx-nf
========================================================================================
 lifebit-ai/pgx-nf Pharamacogenomics Pipeline.
 #### Homepage / Documentation
 https://github.com/lifebit-ai/pgx-nf
----------------------------------------------------------------------------------------
*/

Channel
  .fromPath(params.cell_annotation)
  .ifEmpty { exit 1, "Cell annotation CSV file not found: ${params.cell_annotation}" }
  .into { cell_annotation; tissue_annotation }
Channel
  .fromPath(params.drug_annotation)
  .ifEmpty { exit 1, "Drug annotation CSV file not found: ${params.drug_annotation}" }
  .set { drug_annotation }
Channel
  .fromPath(params.published_info)
  .ifEmpty { exit 1, "Published info XLSX file not found: ${params.published_info}" }
  .set { published_info }
Channel
  .fromPath(params.drug_raw)
  .ifEmpty { exit 1, "Raw drug dose reponse CSV file not found: ${params.drug_raw}" }
  .set { drug_raw }
Channel
  .fromPath(params.drug_conc)
  .ifEmpty { exit 1, "Raw drug dose reponse CSV file not found: ${params.drug_conc}" }
  .set { drug_conc }
Channel
  .fromPath(params.gr_values)
  .ifEmpty { exit 1, "GR values TSV file not found: ${params.gr_values}" }
  .set { gr_values }
Channel
  .fromPath(params.crosscell)
  .ifEmpty { exit 1, "Cross referencing cells TXT file not found: ${params.crosscell}" }
  .set { crosscell }
Channel
  .fromPath(params.crossdrug)
  .ifEmpty { exit 1, "Cross referencing drug TXT file not found: ${params.crossdrug}" }
  .set { crossdrug }
// rnaseq
Channel
  .fromPath(params.rnaseqmatrix)
  .ifEmpty { exit 1, "RNA-Seq matrix TXT file not found: ${params.rnaseqmatrix}" }
  .set { rnaseqmatrix }
Channel
  .fromPath(params.rnaseqpdata)
  .ifEmpty { exit 1, "RNA-Seq info CSV file not found: ${params.rnaseqpdata}" }
  .set { rnaseqpdata }
Channel
  .fromPath(params.rnaseqfdata)
  .ifEmpty { exit 1, "RNA-Seq feature CSV file not found: ${params.rnaseqfdata}" }
  .set { rnaseqfdata }
Channel
  .fromPath(params.rnaseqexp)
  .ifEmpty { exit 1, "RNA-Seq expression TXT file not found: ${params.rnaseqexp}" }
  .set { rnaseqexp }
Channel
  .fromPath(params.rnaseqcounts)
  .ifEmpty { exit 1, "RNA-Seq counts TXT file not found: ${params.rnaseqcounts}" }
  .set { rnaseqcounts }
// rppa
Channel
  .fromPath(params.rppaexp)
  .ifEmpty { exit 1, "RPPA expresion XLSX file not found: ${params.rppaexp}" }
  .set { rppaexp }
Channel
  .fromPath(params.rppapdata)
  .ifEmpty { exit 1, "RPPA protein info CSV file not found: ${params.rppapdata}" }
  .set { rppapdata }
Channel
  .fromPath(params.rppafdata)
  .ifEmpty { exit 1, "RPPA feature CSV file not found: ${params.rppafdata}" }
  .set { rppafdata }
// rna
Channel
  .fromPath(params.rnau133aexp)
  .ifEmpty { exit 1, "RNA expression TXT file not found: ${params.rnau133aexp}" }
  .set { rnau133aexp }
Channel
  .fromPath(params.rnau133apdata)
  .ifEmpty { exit 1, "RNA TXT file not found: ${params.rnau133apdata}" }
  .set { rnau133apdata }
Channel
  .fromPath(params.rnau133afdata)
  .ifEmpty { exit 1, "RNA TXT file not found: ${params.rnau133afdata}" }
  .set { rnau133afdata }
Channel
  .fromPath(params.rnaexonexp)
  .ifEmpty { exit 1, "RNA expression TXT file not found: ${params.rnaexonexp}" }
  .set { rnaexonexp }
Channel
  .fromPath(params.rnaexonpdata)
  .ifEmpty { exit 1, "RNA exon TXT file not found: ${params.rnaexonpdata}" }
  .set { rnaexonpdata }
Channel
  .fromPath(params.rnaexonfdata)
  .ifEmpty { exit 1, "RNA exon TXT file not found: ${params.rnaexonfdata}" }
  .set { rnaexonfdata }
Channel
  .fromPath(params.rnaseqfeature)
  .ifEmpty { exit 1, "RNA-Seq feature CSV file not found: ${params.rnaseqfeature}" }
  .set { rnaseqfeature }
// cnv
Channel
  .fromPath(params.snpexp)
  .ifEmpty { exit 1, "CNV TXT file not found: ${params.snpexp}" }
  .set { snpexp }
Channel
  .fromPath(params.cnvpdata)
  .ifEmpty { exit 1, "CNV info CSV file not found: ${params.cnvpdata}" }
  .set { cnvpdata }
Channel
  .fromPath(params.cnvfdata)
  .ifEmpty { exit 1, "CNV annotation CSV file not found: ${params.cnvfdata}" }
  .set { cnvfdata }
// methylation
Channel
  .fromPath(params.methylationmatrix)
  .ifEmpty { exit 1, "Methylation TXT file not found: ${params.methylationmatrix}" }
  .set { methylationmatrix }
Channel
  .fromPath(params.methylationpdata)
  .ifEmpty { exit 1, "Methylation info CSV file not found: ${params.methylationpdata}" }
  .set { methylationpdata }
Channel
  .fromPath(params.methylationfdata)
  .ifEmpty { exit 1, "Methylation info CSV file not found: ${params.methylationfdata}" }
  .set { methylationfdata }

/*--------------------------------------------------
  Compile cell curation
---------------------------------------------------*/

process compilecellcuration {

  tag "$cell_annotation"
  container 'bhklab/pharmacogxcwl'

  input:
  file(cell_annotation) from cell_annotation

  output:
  set file("cell_cur.RData") into cellcuration_tissue, cellcuration_cellline, cellcuration_recomput, cellcuration_rnaseq, cellcuration_rna, cellcuration_gray

  script:
  """
  cell_curation.R $cell_annotation
  """
}

/*--------------------------------------------------
  Compile tissue curation
---------------------------------------------------*/

process compiletissuecuration {

  tag "$cellcuration"
  container 'bhklab/pharmacogxcwl'

  input:
  file(cellcuration) from cellcuration_tissue
  file(tissue_annotation) from tissue_annotation

  output:
  file("tissue_cur.RData") into tissuecuration

  script:
  """
  tissue_curation.R $tissue_annotation $cellcuration
  """
}

/*--------------------------------------------------
  Compile drug curation
---------------------------------------------------*/

process compiledrugcuration {

  tag "$drug_annotation"
  container 'bhklab/pharmacogxcwl'

  input:
  file(drug_annotation) from drug_annotation

  output:
  set file("drug_cur.RData") into drugcuration_recomput, drugcuration_gray

  script:
  """
  drug_curation.R $drug_annotation
  """
}

/*--------------------------------------------------
  Compile cell line info
---------------------------------------------------*/

process compilecelllineinfo {

  tag "$cellcuration"
  container 'bhklab/pharmacogxcwl'

  input:
  file(cellcuration) from cellcuration_cellline
  file(published_info) from published_info

  output:
  file("cellline_info.RData") into celllineinfo

  script:
  """
  cellline_info.R $published_info $cellcuration
  """
}

/*--------------------------------------------------
  Recomputation
---------------------------------------------------*/

process recomputation {

  tag "${cellcuration},${drugcuration}"
  container 'bhklab/pharmacogxcwl'

  input:
  file(cellcuration) from cellcuration_recomput
  file(drugcuration) from drugcuration_recomput
  file(drug_raw) from drug_raw
  file(drug_conc) from drug_conc
  file(gr_values) from gr_values
  file(crosscell) from crosscell
  file(crossdrug) from crossdrug

  output:
  file("drug_norm_post2017.RData") into drugnormpost
  file("GRAYrecomputed_2017.RData") into gray_recomputed2017

  script:
  """
  recomputed_2017.R \
    $cellcuration \
    $drugcuration \
    $drug_raw \
    $drug_conc \
    $gr_values \
    $crosscell \
    $crossdrug
  """
}

/*--------------------------------------------------
  Compile RNA-Seq
---------------------------------------------------*/

process compileRNAseq {

  tag "$cellcuration"
  container 'bhklab/pharmacogxcwl'

  input:
  file(cellcuration) from cellcuration_rnaseq
  file(matrix) from rnaseqmatrix
  file(rnaseqinfo) from rnaseqpdata
  file(rnaseqfeature) from rnaseqfdata
  file(expression) from rnaseqexp
  file(counts) from rnaseqcounts

  output:
  file("RNAseq_processed.RData") into rnaseq

  script:
  """
  rna_seq.R \
    $cellcuration \
    $matrix \
    $rnaseqinfo \
    $rnaseqfeature \
    $expression \
    $counts
  """
}

/*--------------------------------------------------
  Compile RPPA
---------------------------------------------------*/

process compileRPPA {

  tag "${expression},${proteininfo}"
  container 'bhklab/pharmacogxcwl'

  input:
  file(expression) from rppaexp
  file(proteininfo) from rppapdata
  file(proteinfeature) from rppafdata

  output:
  file("RPPA_processed.RData") into rppa

  script:
  """
  rppa.R $expression $proteininfo $proteinfeature
  """
}

/*--------------------------------------------------
  Compile RNA
---------------------------------------------------*/

process compileRNA {

  tag "$cellcuration"
  container 'bhklab/pharmacogxcwl'

  input:
  file(cellcuration) from cellcuration_rna
  file(u133aexp) from rnau133aexp
  file(u133ainfo) from rnau133apdata
  file(u133afeature) from rnau133afdata
  file(exonexp) from rnaexonexp
  file(exoninfo) from rnaexonpdata
  file(exonfeature) from rnaexonfdata

  output:
  file("RNA_processed.RData") into rna

  script:
  """
  rna.R \
    $cellcuration \
    $u133aexp \
    $u133ainfo \
    $u133afeature \
    $exonexp \
    $exoninfo \
    $exonfeature
  """
}

/*--------------------------------------------------
  Compile CNV
---------------------------------------------------*/

process compileCNV {

  tag "${snp6},${cnvinfo}"
  container 'bhklab/pharmacogxcwl'

  input:
  file(snp6) from snpexp
  file(cnvinfo) from cnvpdata
  file(cnvfeature) from cnvfdata

  output:
  file("cnv_processed.RData") into cnv

  script:
  """
  cnv.R $snp6 $cnvinfo $cnvfeature
  """
}

/*--------------------------------------------------
  Compile Methylation
---------------------------------------------------*/

process compileMethylation {

  tag "${matrix},${methylationinfo}"
  container 'bhklab/pharmacogxcwl'

  input:
  file(matrix) from methylationmatrix
  file(methylationinfo) from methylationpdata
  file(methylationfeature) from methylationfdata

  output:
  file("Methylation_processed.RData") into methylation

  script:
  """
  methylation.R $matrix $methylationinfo $methylationfeature
  """
}

/*--------------------------------------------------
  Get GRAY2017 PSet
---------------------------------------------------*/

process getGRAY2017PSet {

  tag "${gray_recomputed2017}"
  container 'bhklab/pharmacogxcwl'
  publishDir "${params.outdir}", mode: 'copy'

  input:
  file(cellcuration) from cellcuration_gray
  file(tissue_annotation) from tissuecuration
  file(drugcuration) from drugcuration_gray
  file(celllineinfo) from celllineinfo
  file(drugnormpost) from drugnormpost
  file(gray_recomputed2017) from gray_recomputed2017
  file(rnaseq) from rnaseq
  file(rppa) from rppa
  file(rna) from rna
  file(cnv) from cnv
  file(methylation) from methylation

  output:
  file("GRAY_2017.RData") into GRAY2017

  script:
  """
  GRAY2017.R \
    $cellcuration \
    $tissue_annotation \
    $drugcuration \
    $celllineinfo \
    $drugnormpost \
    $gray_recomputed2017 \
    $rnaseq \
    $rppa \
    $rna \
    $cnv \
    $methylation
  """
}