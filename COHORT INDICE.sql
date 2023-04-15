/* BASE DE DONNEES */

  select *
  from OnlineRetail

/*-- TABLE FILTRE AVEC CustomerID, Unitprice et Quantité non nuls
RECHERCHE DE DOUBLONS */
select * ,
ROW_NUMBER () OVER (PARTITION BY InvoiceNo, StockCode, Quantity order by 
CustomerID) as doublons
into #Tablepropre
from 
(
Select *
from OnlineRetail
WHERE CustomerID !=0 and Quantity > 0 and UnitPrice > 0
)CTE2

/*Table FILTRE SANS DOUBLONS */
DELETE 
from #Tablepropre
WHERE doublons > 1
--order by doublons desc
  /*COHORT ANALYSE (% DE CLIENTS REVENUE APRES LEUR 1ER ACHAT*/
--Détermination du 1er jour d'achat de chq client (4338 clients)

DROP TABLE IF EXISTS #Cohort
select *, DATEFROMPARTS(YEAR(PremDateAchat),MONTH(PremDateAchat),1)CohortDate
into #Cohort
from
	(
	select CustomerID, MIN(InvoiceDate)PremDateAchat
	from #Tablepropre
	GROUP BY CustomerID
	)PremiereDate

--CREATION INDICE DE COHORT
DROP TABLE IF EXISTS #CohortIndice
Select *
into #CohortIndice
from
	(	
	Select *, ((DiffAnn*12)+DiffMois)+1 as COHORT_INDEX
	from
		(
		Select *, (AnndernAchat-AnnpremAchat)DiffAnn,
							 (MoisdernAchat-MoispremAchat)DiffMois
		from (
			Select *, YEAR(CohortDate)AnnpremAchat, MONTH(CohortDate)MoispremAchat,
					  YEAR(InvoiceDate)AnndernAchat, MONTH(InvoiceDate)MoisdernAchat		
			from
				(
				select tp.*, Co.CohortDate
				from #Cohort Co
				left join #Tablepropre tp
				ON Co.CustomerID = tp.CustomerID
				)Tablejointe
			)AnnetMois
		)Diff
)Cohort

/*ENREGISTREMENT POUR TABLEAU */
select *
from #CohortIndice

--CREATION DE LA TABLE PIVOT (TABLE FINALE)
DROP TABLE IF EXISTS #PIVOTTABLE
select *
into #PIVOTTABLE
from
(
select DISTINCT(CustomerID), CohortDate,COHORT_INDEX

from #CohortIndice
)Pivottable
PIVOT (
COUNT(CustomerID)	FOR COHORT_INDEX
		IN ([1],
			[2],
			[3],
			[4],
			[5],
			[6],
			[7],
			[8],
			[9],
			[10],
			[11],
			[12],
			[13]
			)
			) as PIVOTTABLE
		ORDER BY CohortDate

/* VISUALISATION COHORT INDICE*/

select *
from #PIVOTTABLE
ORDER BY CohortDate
