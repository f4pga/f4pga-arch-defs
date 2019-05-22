<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

  <xsl:include href="identity.xsl" />

  <!-- template-function: Allow from attribute which gives you a relative to a given pb_type -->
  <xsl:template name="from-pb_type">
    <xsl:choose>
      <xsl:when test="@from='current'"><xsl:value-of select="ancestor::pb_type[1]/@name"/></xsl:when>
      <xsl:when test="@from"><xsl:value-of select="@from"/></xsl:when>
      <xsl:otherwise><xsl:value-of select="ancestor::pb_type[1]/@name"/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- template-function: Called to convert
     * <port name=XXX>                      to XXX
     * <port name=XXX bit=Y>                to XXX[Y]
     * <port name=XXX bit_msb=M bit_lsb=L>  to XXX[M:L]
    -->
  <xsl:template name="port-value"><xsl:value-of select="@name"/><xsl:choose><xsl:when test="@bit">[<xsl:value-of select="@bit"/>]</xsl:when><xsl:when test="@bit-msb">[<xsl:value-of select="@bit-msb"/>:<xsl:value-of select="@bit-lsb"/>]</xsl:when><xsl:otherwise></xsl:otherwise></xsl:choose></xsl:template>

  <!-- Testing matcher for the port-value template function -->
  <xsl:template match="port-value-test/port">
    <xsl:attribute name="o">
      <xsl:call-template name="port-value"/>
    </xsl:attribute>
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
      <xsl:if test="metadata">
        <metadata>
          <!-- The fasm_mux metadata attribute needs special handling. -->
          <xsl:if test="*/metadata/meta[@name='fasm_mux']">
            <meta name="fasm_mux"><xsl:text>&#xa;</xsl:text>
              <xsl:for-each select="port[@type='input']">
                <xsl:call-template name="from-pb_type"/>.<xsl:call-template name="port-value"/><xsl:text> : </xsl:text><xsl:value-of select="metadata/meta[@name='fasm_mux']" /><xsl:text>&#xa;</xsl:text>
              </xsl:for-each>
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

</xsl:stylesheet>
