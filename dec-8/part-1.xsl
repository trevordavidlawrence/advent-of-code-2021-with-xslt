<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:array="http://www.w3.org/2005/xpath-functions/array"
                xmlns:map="http://www.w3.org/2005/xpath-functions/map"
                xmlns:math="http://www.w3.org/2005/xpath-functions/math"
                xmlns:tdl="whatever"
                exclude-result-prefixes="#all"
                expand-text="yes"
                version="3.0">

    <xsl:output method="text"/>

    <xsl:variable name="input" as="xs:string +"
        select="unparsed-text-lines('input.txt')"/>

    <xsl:variable name="entries" as="map(*) +" select="$input ! tdl:parse-entry(.)"/>
    
    <xsl:template name="xsl:initial-template">
       <xsl:sequence select="sum($entries ! tdl:easy-digit-count(.))"/>
    </xsl:template>

    <xsl:function name="tdl:parse-entry" as="map(*)">
        <xsl:param name="entry" as="xs:string"/>

        <xsl:sequence select="
            map {
                'patterns': $entry => substring-before(' |') => tokenize(),
                'digits': $entry => substring-after('| ') => tokenize()
            }
        "/>
    </xsl:function>

    <xsl:function name="tdl:easy-digit-count" as="xs:integer">
        <xsl:param name="entry" as="map(*)"/>

        <xsl:sequence select="count(($entry?digits)[string-length(.) = (2, 3, 4, 7)])"/>
    </xsl:function>

    <xsl:function name="tdl:split-string" as="xs:string *">
        <xsl:param name="string" as="xs:string"/>
        
        <xsl:sequence select="string-to-codepoints($string) ! codepoints-to-string(.)"/>
    </xsl:function>

</xsl:stylesheet>