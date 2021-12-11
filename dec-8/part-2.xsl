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

    <xsl:variable name="digit-mapping" as="map(xs:string, xs:integer)"
        select="
            map {
                'abcefg': 0,
                'cf': 1,
                'acdeg': 2,
                'acdfg': 3,
                'bcdf': 4,
                'abdfg': 5,
                'abdefg': 6,
                'acf': 7,
                'abcdefg': 8,
                'abcdfg': 9
            }
        "/>
    
    <xsl:template name="xsl:initial-template">
       <xsl:sequence select="sum($entries ! tdl:decode(.))"/>
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

    <xsl:function name="tdl:decode" as="xs:integer">
        <xsl:param name="entry" as="map(*)"/>

        <xsl:sequence select="tdl:map-digits(tdl:wire-mapping($entry), $entry?digits)"/>
    </xsl:function>

    <xsl:function name="tdl:wire-mapping" as="map(xs:string, xs:string)">
        <xsl:param name="entry" as="map(*)"/>

        <xsl:variable name="digit1" as="xs:string +"
            select="$entry?patterns[string-length() eq 2] => tdl:split-string()"/>

        <xsl:variable name="digit4" as="xs:string +"
            select="$entry?patterns[string-length() eq 4] => tdl:split-string()"/>

        <xsl:variable name="digit7" as="xs:string +"
            select="$entry?patterns[string-length() eq 3] => tdl:split-string()"/>

        <xsl:variable name="digit8" as="xs:string +"
            select="$entry?patterns[string-length() eq 7] => tdl:split-string()"/>

        <xsl:variable name="a" as="xs:string" select="$digit7[not(. = $digit1)]"/>

        <xsl:variable name="digit6" as="xs:string +"
            select="$entry?patterns[string-length() eq 6][not(contains(., $digit1[1]) and contains(., $digit1[2]))] => tdl:split-string()"/>

        <xsl:variable name="f" as="xs:string" select="$digit6[. = $digit1]"/>

        <xsl:variable name="c" as="xs:string" select="$digit1[not(. eq $f)]"/>

        <xsl:variable name="digit3" as="xs:string +"
            select="$entry?patterns[string-length() eq 5][contains(., $c) and contains(., $f)] => tdl:split-string()"/>

        <xsl:variable name="d" as="xs:string"
            select="$digit3[not(. = $digit7)][. = $digit4]"/>

        <xsl:variable name="g" as="xs:string" select="$digit3[not(. = ($a, $c, $d, $f))]"/>

        <xsl:variable name="b" as="xs:string"
            select="$digit8[not(. = $digit3)][. = $digit4]"/>

        <xsl:variable name="e" as="xs:string" select="$digit8[not(. = $digit3) and (. ne $b)]"/>

        <xsl:map>
            <xsl:map-entry key="$a" select="'a'"/>
            <xsl:map-entry key="$b" select="'b'"/>
            <xsl:map-entry key="$c" select="'c'"/>
            <xsl:map-entry key="$d" select="'d'"/>
            <xsl:map-entry key="$e" select="'e'"/>
            <xsl:map-entry key="$f" select="'f'"/>
            <xsl:map-entry key="$g" select="'g'"/>
        </xsl:map>
    </xsl:function>

    <xsl:function name="tdl:map-digits" as="xs:integer">
        <xsl:param name="wire-mapping" as="map(xs:string, xs:string)"/>
        <xsl:param name="digits" as="xs:string +"/>

        <xsl:sequence
            select="($digits ! (string(tdl:map-digit($wire-mapping, .)))) => string-join() => xs:integer()"/>
    </xsl:function>

    <xsl:function name="tdl:map-digit" as="xs:integer">
        <xsl:param name="wire-mapping" as="map(xs:string, xs:string)"/>
        <xsl:param name="digit" as="xs:string"/>

        <xsl:sequence select="
            let $decoded-digit := (tdl:split-string($digit) ! $wire-mapping(.)) => sort() => string-join()
            return $digit-mapping($decoded-digit)
            "/>
    </xsl:function>

    <xsl:function name="tdl:split-string" as="xs:string *">
        <xsl:param name="string" as="xs:string"/>
        
        <xsl:sequence select="string-to-codepoints($string) ! codepoints-to-string(.)"/>
    </xsl:function>

</xsl:stylesheet>