<?xml version="1.0"?>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	
	<xsl:output method="html" indent="no" encoding="US-ASCII"/>
		<xsl:param name="context"/>
		<xsl:param name="renderId"/>
		<xsl:param name="token"/>
		<xsl:param name="pivotId"/>
		
		<xsl:include href="../../wcf/controls.xsl"/>
		
		<!-- buttons with spaces inbetween -->
		<!--xsl:template match="button[@hidden='true']"/-->
		
		<xsl:template match="button">
			<xsl:text> </xsl:text>
			<input type="image" name="{@id}" alt="{@label}" title="{@label}" class="imgButton">
				<xsl:attribute name="src">
					<xsl:value-of select="$context"/>
					<xsl:text>/stpivot/style/jpivot/navi/button_</xsl:text>
					<xsl:value-of select="substring-after(@id,'.membernav.')"/>
					<xsl:text>.png</xsl:text>
				</xsl:attribute>
			</input>
			<xsl:text> </xsl:text>
		</xsl:template>
		
		<xsl:template match="tree-extras-top | tree-extras-bottom">
			<tr>
				<td class="navi-hier" width="100%">
					<xsl:apply-templates/>
				</td>
			</tr>
		</xsl:template>
		
		<xsl:include href="../../wcf/changeorder.xsl"/>
		<xsl:include href="hierarchy-navigator.xsl"/>
		<xsl:include href="../../wcf/xtree.xsl"/>
		<xsl:include href="../../wcf/identity.xsl"/>
		
</xsl:stylesheet>
