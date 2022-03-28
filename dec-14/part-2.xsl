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

    <xsl:variable name="template" as="xs:string" select="$input[1]"/>

    <xsl:variable name="rules" as="map(*)" select="map:merge($input[position() ge 3] ! tdl:parse-rule(.))"/>
    
    <xsl:template name="xsl:initial-template">
        <xsl:variable name="pair-frequencies" as="map(xs:string, xs:integer)"
            select="tdl:polymerize($template, 40)"/>

        <xsl:variable name="frequencies" as="xs:integer *"
            select="let $pairs          := map:keys($pair-frequencies),
                        $materials      := distinct-values($pairs ! substring(., 1, 1)), 
                        $frequencies    :=  map:merge(for $material in $materials
                                            return map {
                                            $material: sum($pairs[starts-with(., $material)] ! $pair-frequencies(.)) }),
                        $final-material := substring($template, string-length($template)),
                        $histogram      := map:put($frequencies, $final-material, $frequencies($final-material) + 1)
                        return sort(map:keys($histogram) ! $histogram(.))
                    "/>

        <xsl:sequence select="$frequencies[last()] - $frequencies[1]"/>
    </xsl:template>

    <xsl:function name="tdl:polymerize" as="map(*)">
        <xsl:param name="template" as="xs:string"/>
        <xsl:param name="steps" as="xs:integer"/>

        <xsl:variable name="initial-frequencies" as="map(xs:string, xs:integer)"
            select="let $pairs :=   for $i in (1 to (string-length($template) - 1))
                                    return (substring($template, $i, 1) || substring($template, $i + 1, 1))
                    return fold-left($pairs, map {}, tdl:add-pairs#2)"/>

        <xsl:sequence select="fold-left((1 to $steps), $initial-frequencies,
            function($frequencies, $_) { tdl:_polymerize($frequencies) })"/>
    </xsl:function>

    <xsl:function name="tdl:_polymerize" as="map(*)">
        <xsl:param name="pair-frequencies" as="map(*)"/>

        <xsl:sequence select="
            let $pairs := map:keys($pair-frequencies)
            return fold-left($pairs, map {}, function($freq-acc, $pair) {
                let $count := $pair-frequencies($pair),
                    $result := $rules($pair),
                    $new-pairs := ((substring($pair, 1, 1) || $result), ($result || substring($pair, 2, 1)))
                return tdl:add-pairs($freq-acc, $new-pairs, $count)
            })
        "/>
    </xsl:function>

    <xsl:function name="tdl:add-pairs" as="map(*)">
        <xsl:param name="frequencies" as="map(*)"/>
        <xsl:param name="pairs" as="xs:string *"/>
        
        <xsl:sequence select="tdl:add-pairs($frequencies, $pairs, 1)"/>
    </xsl:function>

    <xsl:function name="tdl:add-pairs" as="map(*)">
        <xsl:param name="frequencies" as="map(*)"/>
        <xsl:param name="pairs" as="xs:string *"/>
        <xsl:param name="count" as="xs:integer"/>

        <xsl:sequence
            select="fold-left($pairs, $frequencies,
                    function($freq-acc, $pair) {
                        let $curr-freq := $freq-acc($pair)
                        return
                            if (exists($curr-freq)) 
                            then map:put($freq-acc, $pair, $curr-freq + $count)
                            else map:put($freq-acc, $pair, $count)
                    })"/>
    </xsl:function>

    <xsl:function name="tdl:parse-rule" as="map(xs:string, xs:string)">
        <xsl:param name="rule" as="xs:string"/>
        
        <xsl:analyze-string select="$rule" regex="^([A-Z]{{2}}) -> ([A-Z])$">
            <xsl:matching-substring>
                <xsl:map-entry key="regex-group(1)" select="regex-group(2)"/>
            </xsl:matching-substring>
        </xsl:analyze-string>
    </xsl:function>

    <xsl:function name="tdl:split-string" as="xs:string *">
        <xsl:param name="string" as="xs:string"/>
        
        <xsl:sequence select="string-to-codepoints($string) ! codepoints-to-string(.)"/>
    </xsl:function>

</xsl:stylesheet>