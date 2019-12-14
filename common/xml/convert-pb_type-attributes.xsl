<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

  <xsl:include href="identity.xsl" />

  <xsl:template match="pb_type">
    <xsl:copy>
      <!--
        Convert
          <pb_type><blif_model>XXX</blif_model></pb_type>
        to
          <pb_type blif_model="XXX"></pb_type>
        -->
      <xsl:if test="blif_model">
        <xsl:attribute name="blif_model"><xsl:value-of select="blif_model/text()"/></xsl:attribute>
      </xsl:if>
      <!-- Inherit 'num_pb' attribute from pb_array elements -->
      <xsl:if test="parent::pb_array/@num_pb">
        <xsl:attribute name="num_pb"><xsl:value-of select="parent::pb_array/@num_pb"/></xsl:attribute>
      </xsl:if>
      <!--
        Convert
          <pb_type><pb_class>XXX</pb_class></pb_type>
        to
          <pb_type class="XXX"></pb_type>
        -->
      <xsl:if test="pb_class">
        <xsl:attribute name="class"><xsl:value-of select="pb_class/text()"/></xsl:attribute>
      </xsl:if>
      <xsl:apply-templates select="@*"/>
      <xsl:apply-templates select="node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="pb_type/blif_model"/>
  <xsl:template match="pb_type/pb_class"/>

  <!-- Copy pb_type elements out of pb_array elements -->
  <xsl:template match="pb_array">
    <xsl:apply-templates/>
  </xsl:template>

</xsl:stylesheet>
