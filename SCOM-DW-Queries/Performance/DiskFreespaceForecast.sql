-- Based on the last 90 days, calculate a trend forecast for when the logicaldisk will run out of space, in days
select Convert(int,-(Intercept + N*Slope) / Slope) as DaysRemaining
from
(
  select Slope, Intercept=(SumY-Slope*SumX)/N, N
  from 
  (
    select Slope=(N*SumXY-SumX*SumY)/(N*SumXX-SumX*SumX)
          ,SumY
          ,SumX
          ,N
    from 
    (
select   
         SumXY=sum(x*y)*1.00
             ,SumX=sum(x)*1.00
             ,SumY=sum(y)*1.00
             ,SumXX=sum(x*x)*1.00
             ,SumYY=sum(y*y)*1.00
             ,N=count(*)*1.00
 FROM (
SELECT row_number() OVER (ORDER BY p.DateTime ASC) AS x, p.AverageValue AS y
FROM Perf.vPerfDaily AS p
JOIN vPerformanceRuleInstance AS pri ON p.PerformanceRuleInstanceRowId = pri.PerformanceRuleInstanceRowId
JOIN vRule AS r ON pri.RuleRowId = r.RuleRowId
JOIN vPerformanceRule AS pr ON r.RuleRowId = pr.RuleRowId
JOIN vManagedEntity AS me ON p.ManagedEntityRowId = me.ManagedEntityRowId
WHERE pr.ObjectName = 'LogicalDisk' AND pr.CounterName = '% Free Space' AND me.ManagedEntityGuid = {{id}}
AND p.DateTime >= DATEADD(day, -90, CONVERT(date, GETDATE()))
) indexed
     ) CalcSums
  ) CalcSlope
) CalcIntercept 
