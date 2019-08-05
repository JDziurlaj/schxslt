xquery version "3.1";

(:~
 : BaseX module for Schematron validation with SchXslt.
 :
 : @author David Maus
 : @see    https://doi.org/10.5281/zenodo.1495494
 : @see    https://basex.org
 :
 :)

module namespace schxslt = "https://doi.org/10.5281/zenodo.1495494";

declare namespace svrl = "http://purl.oclc.org/dsdl/svrl";
declare namespace sch = "http://purl.oclc.org/dsdl/schematron";
declare namespace xsl = "http://www.w3.org/1999/XSL/Transform";

(:~
 : Validate document against Schematron and return the validation report.
 :
 : @param  $document   Document to be validated
 : @param  $schematron Schematron schema
 : @param  $phase      Validation phase
 : @return Validation report
 :)
declare function schxslt:validate ($document as node(), $schematron as node(), $phase as xs:string?) as document-node(element(svrl:schematron-output)) {
  let $options := if ($phase) then map{"phase": $phase} else map{}
  let $schematron := if ($schematron instance of document-node()) then $schematron/sch:schema else $schematron
  let $xsltver := schxslt:processor-path(lower-case($schematron/@queryBinding))
  return
    $document => xslt:transform(schxslt:compile($schematron, $options, $xsltver))
};

(:~
 : Validate document against Schematron and return the validation report.
 :
 : @param  $document Document to be validated
 : @param  $schematron Schematron document
 : @return Validation report
 :)
declare function schxslt:validate ($document as node(), $schematron as node()) as document-node(element(svrl:schematron-output)) {
  schxslt:validate($document, $schematron, ())
};

(:~
 : Return path segment to processor for requested query language.
 :
 : @error  Query language not supported
 :
 : @param  $queryBinding Query language token
 : @return Path segment to processor
 :)
declare %private function schxslt:processor-path ($queryBinding as xs:string) as xs:string {
  switch ($queryBinding)
    case ""
      return "1.0"
    case "xslt"
      return "1.0"
    case "xslt2"
      return "2.0"
    default
      return error(xs:QName("schxslt:UnsupportedQueryBinding"))
};

(:~
 : Compile Schematron to validation stylesheet.
 :
 : @param  $schematron Schematron document
 : @param  $options Schematron compiler parameters
 : @return Validation stylesheet
 :)
declare %private function schxslt:compile ($schematron as node(), $options as map(*), $xsltver as xs:string) as document-node(element(xsl:transform)) {
  let $basedir := file:base-dir() || "/xslt/" || $xsltver || "/"
  let $include := $basedir || "include.xsl"
  let $expand  := $basedir || "expand.xsl"
  let $compile := $basedir || "compile-for-svrl.xsl"
  return
    $schematron => xslt:transform($include) => xslt:transform($expand) => xslt:transform($compile, $options)
};