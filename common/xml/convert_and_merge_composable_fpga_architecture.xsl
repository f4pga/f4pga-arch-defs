<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

  <xsl:output method="xml" indent="yes"/>
  <xsl:strip-space elements="*"/>

  <!-- template-function: Allow from attribute which gives you a relative to a given pb_type -->
  <xsl:template name="from-pb_type">
    <xsl:choose>
      <xsl:when test="@from='current'"><xsl:value-of select="ancestor::pb_type[1]/@name"/></xsl:when>
      <xsl:when test="@from"><xsl:value-of select="@from"/></xsl:when>
      <xsl:otherwise><xsl:value-of select="ancestor::pb_type[1]/@name"/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- template-function: Called to convert
     * <port name=XXX> 				to XXX
     * <port name=XXX bit=Y> 			to XXX[Y]
     * <port name=XXX bit_msb=M bit_lsb=L>	to XXX[M:L]
    -->
  <xsl:template name="port-value"><xsl:value-of select="@name"/><xsl:choose><xsl:when test="@bit">[<xsl:value-of select="@bit"/>]</xsl:when><xsl:when test="@bit-msb">[<xsl:value-of select="@bit-msb"/>:<xsl:value-of select="@bit-lsb"/>]</xsl:when><xsl:otherwise></xsl:otherwise></xsl:choose></xsl:template>

  <!-- Testing matcher for the port-value template function -->
  <xsl:template match="port-value-test/port">
    <xsl:attribute name="o">
      <xsl:call-template name="port-value"/>
    </xsl:attribute>
  </xsl:template>

  <!-- Root match -->
  <xsl:template match="/">
    <xsl:apply-templates/>
  </xsl:template>

  <!-- Normalize space around attributes on a tag -->
  <xsl:template match="@*">
    <xsl:copy>
      <xsl:value-of select="normalize-space( . )" />
    </xsl:copy>
  </xsl:template>

  <!-- Sort the attributes by name -->
  <xsl:template match="*">
    <xsl:copy>
      <xsl:apply-templates select="@*" >
	<xsl:sort select="name()"/>
      </xsl:apply-templates>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <!-- Strip xml:base attribute -->
  <xsl:template match="@xml:base"/>

  <!--
    Strip pack_pattern's from input/output tags on pb_types.
    -->
  <xsl:template match="pb_type/input/pack_pattern"/>
  <xsl:template match="pb_type/output/pack_pattern"/>

  <!--
    Convert
       <pack_pattern name="xxx" type="yyy
    to
       <pack_pattern name="yyy-xxx"
    -->
  <xsl:template match="pack_pattern/@type"/>
  <xsl:template match="pack_pattern[@type]/@name">
    <xsl:attribute name="name">
      <xsl:value-of select="../@type"/>-<xsl:value-of select="../@name"/>
    </xsl:attribute>
  </xsl:template>
  <xsl:template match="pack_pattern[not(@type)]/@name">
    <xsl:copy />
  </xsl:template>
  <xsl:template match="pack_pattern/*">
    <xsl:copy />
  </xsl:template>

  <!-- Prefix in_port / out_port values with the parent name. -->
  <xsl:template match="@out_port">
    <xsl:attribute name="out_port"><xsl:call-template name="from-pb_type"/>.<xsl:value-of select="."/></xsl:attribute>
  </xsl:template>
  <xsl:template match="@in_port">
    <xsl:attribute name="in_port"><xsl:call-template name="from-pb_type"/>.<xsl:value-of select="."/></xsl:attribute>
  </xsl:template>

  <!--
    Convert
      <interconnect><direct><port type='input' ...><port type='output' ...></direct><YYY../></interconnect>
    to
      <interconnect><direct input='...' name='xxx-xxx' output='...'><YYY../></direct></interconnect>
    -->
  <xsl:template match="interconnect/direct/port[@type='input']">
    <xsl:attribute name="input"><xsl:call-template name="from-pb_type"/>.<xsl:call-template name="port-value"/></xsl:attribute>
  </xsl:template>
  <xsl:template match="interconnect/direct/port[@type='output']">
    <xsl:attribute name="name"><xsl:call-template name="from-pb_type"/>-<xsl:call-template name="port-value"/></xsl:attribute>
    <xsl:attribute name="output"><xsl:call-template name="from-pb_type"/>.<xsl:call-template name="port-value"/></xsl:attribute>
  </xsl:template>

  <!--
    Convert
      <interconnect><xxx><pack_pattern><port type='input' ...><port type='output' ...></pack_pattern></xxx><YYY../></interconnect>
    to
      <interconnect><xxx><pack_pattern in_port="XXXX" out_port="XXXX" /></xxx></interconnect>
    -->
  <xsl:template match="pack_pattern/port[@type='input']">
    <xsl:attribute name="in_port"><xsl:call-template name="from-pb_type"/>.<xsl:call-template name="port-value"/></xsl:attribute>
  </xsl:template>
  <xsl:template match="pack_pattern/port[@type='output']">
    <xsl:attribute name="out_port"><xsl:call-template name="from-pb_type"/>.<xsl:call-template name="port-value"/></xsl:attribute>
  </xsl:template>

  <!--
    Convert
      <interconnect><mux><port type='input' ...><port type='input' ...><port type='output' ...></mux><YYY../></interconnect>
    to
      <interconnect><mux input='in1 in2' name='xxx-xxx' output='...'><YYY../></mux></interconnect>
    -->
  <xsl:template match="interconnect/mux/port"></xsl:template>
  <xsl:template match="interconnect/mux">
    <xsl:copy>
      <xsl:attribute name="input">
        <xsl:for-each select="port[@type='input']">
          <xsl:call-template name="from-pb_type"/>.<xsl:call-template name="port-value"/>
          <xsl:if test="position() != last()"><xsl:text> </xsl:text></xsl:if>
        </xsl:for-each>
      </xsl:attribute>
      <xsl:attribute name="output">
        <xsl:for-each select="port[@type='output']">
          <xsl:call-template name="from-pb_type"/>.<xsl:call-template name="port-value"/>
        </xsl:for-each>
      </xsl:attribute>
      <xsl:for-each select="@*"><xsl:copy /></xsl:for-each>
      <xsl:apply-templates/>
      <xsl:if test="*/metadata">
        <metadata>
          <!-- The fasm_mux metadata attribute needs special handling. -->
          <xsl:if test="*/metadata/meta[@name='fasm_mux']">
            <meta name="fasm_mux">
              <xsl:for-each select="port[@type='input']"><xsl:text>
                </xsl:text><xsl:call-template name="from-pb_type"/>.<xsl:call-template name="port-value"/><xsl:text> : </xsl:text><xsl:value-of select="metadata/meta[@name='fasm_mux']" />
              </xsl:for-each><xsl:text>
            </xsl:text>
            </meta>
          </xsl:if>
          <xsl:for-each select="metadata">
            <xsl:apply-templates/>
          </xsl:for-each>
        </metadata>
      </xsl:if>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="interconnect/mux/metadata"></xsl:template>

  <!--
    Convert
      <loc ...><port ...><port ...></loc>
    to
      <loc ...>BLOCK.PORT BLOCK.PORT</loc>
    -->
  <xsl:template match="pinlocations/loc/port"><xsl:text>
        </xsl:text><xsl:call-template name="from-pb_type"/>.<xsl:call-template name="port-value"/>
  </xsl:template>
  <xsl:template match="pinlocations/loc/port[last()]"><xsl:text>
        </xsl:text><xsl:call-template name="from-pb_type"/>.<xsl:call-template name="port-value"/><xsl:text>
      </xsl:text>
  </xsl:template>

  <!-- Remove duplicate model nodes -->
  <xsl:key name="model-by-name" match="model" use="@name" />
  <xsl:template match="models">
    <models>
      <xsl:for-each select="model[count(. | key('model-by-name', @name)[1]) = 1]">
        <xsl:copy>
          <xsl:attribute name="name"><xsl:value-of select="@name"/></xsl:attribute>
          <xsl:apply-templates/>
        </xsl:copy>
      </xsl:for-each>
    </models>
  </xsl:template>

  <xsl:param name="strip_comments" select="''" />
  <xsl:template match="comment()">
    <xsl:choose>
      <xsl:when test="$strip_comments"></xsl:when>
	    <xsl:otherwise><xsl:copy /></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="text()|processing-instruction()">
    <xsl:copy/>
  </xsl:template>

</xsl:stylesheet>
