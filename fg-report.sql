-----------------------------------------------------------------------
-- This script check if GD's and FD's had any maintenance alarms last week.
-- This is done by check for specific limits.
-- Hit the ! ikon to run the program.
--
-- Author...: Harald Askeland, TI KAR EA
-- Created..: 05.oct.2012
--
-- History:
-- Date       Sign      Changes
-- 05oct12    HAASK     New program
-- 19oct12    HAASK     Done changes according to requirements from Sigve.
-- 14nov12    HAASK     Will now copy files to G:\GAS\PA\ASPEN at the end.
--------------------------------------------------------------------------
local tid integer,
	dayStart integer,
	dayEnd integer,
	max real,
	min real,
	avg real,
	timeStart timestamp,
	timeend timestamp,
	firstTime timestamp,
	lastTime timestamp,
      hourStep integer,
	minCounter integer,
	maxCounter integer,
	GDmax real,
	GDmin real,
      GD2max real,
	GD2min real,
	FDmin real,
	FDmax real,
	runGD integer,
	runFD integer;

FUNCTION CheckTag(tagname CHAR(20), limMax real, limMin real)
LOCAL timeCurr timestamp,
      timeStep integer;

   timeCurr = timeStart;
   timeStep = hourStep*60*60*10;
   firstTime = current_timestamp;
   lastTime = current_timestamp;
   minCounter=0;
   maxCounter=0;
   while (timeCurr < timeEnd) do
      for (select min, max, avg from aggregates where name like local.tagname and ts between timeCurr and timeCurr + timeStep and period = timeStep) do
         if (min > limMin and min < limMax)  then
            if (firstTime = current_timestamp) then
               firstTime = timeCurr;
            end
            lastTime  = timeCurr;
            minCounter = minCounter + 1;
            if (max > limMax) then
		   maxCounter = maxCounter + 1;
            end
--            write 'counter:'||minCounter||'/'||maxCounter;
         end
       end
      timeCurr = timeCurr + timeStep;
   end
end

Write 'F&&G last week maintenance alarm report.';
write 'Program started:' || cast(getdbtime as char format 'DD.MM.YY HH:MI:SS');

dayStart = 7;	-- Number of days in the past for start time
dayEnd = 0;		-- Number of days in the past for end time, 0=now
hourStep = 1;	-- Number of hours in step

GDmin = -0.4;	-- Minimum range for GD with R suffix
GDmax = -0.05;	-- Maximum range for GD with R suffix

GD2min = -16.25;	-- Minimum range for GD without R suffix
GD2max = -11.25;	-- Maximum range for GD without R suffix


FDmin = -16.25;	-- Minimum range for FD, DF and GD's withour R suffix
FDmax = -11.25;	-- Maximum range for FD, DF and GD's withour R suffix

runGD=1;		-- Change to 0 if you don't want the GD's
runFD=1;		-- Change to 0 if you don't want the FD's


-- Do not change below.
timeStart = current_timestamp - dayStart*24*60*60*10;
timeEnd = current_timestamp - dayEnd*24*60*60*10;


write 'Start time:' || cast(timeStart as char format 'DD.MM.YY HH:MI:SS');
write 'End time:'|| cast(timeEnd as char format 'DD.MM.YY HH:MI:SS');

if (runGD = 1) then
  SET OUTPUT 'C:\logs\FG-report-GDR.csv';
  write 'Date:' || cast(current_timestamp as char format 'DD.MM.YY HH:MI:SS') || ';Report limits: '||GDmin||' <x< '||GDmax;
  write 'Tagname;Description;Counter1;Counter2;First;Last';

  for (select name, ip_description from ip_analogdef where name like '___GD%R' and name not like '%Diff%' order by 1) do
     CheckTag(name, GDmax, GDmin);
     if (minCounter > 0) then
        write name ||';'||ip_description||';'|| minCounter||';'||maxCounter||';'||
		cast(firstTime as char format 'DD.MM.YY HH:MI:SS')||';'||cast(lastTime as char format 'DD.MM.YY HH:MI:SS');
     end
  end

  SET OUTPUT 'C:\logs\FG-report-GD.csv';
  write 'Date:' || cast(current_timestamp as char format 'DD.MM.YY HH:MI:SS') || ';Report limits: '||GD2min||' <x< '||GD2max;
  write 'Tagname;Description;Counter1;Counter2;First;Last';

  for (select name, ip_description from ip_analogdef where (name like '___GD%' or name like '__GD%') and name not like '%Diff%' order by 1) do
     CheckTag(name, GD2max, GD2min);
     if (minCounter > 0) then
        write name ||';'||ip_description||';'|| minCounter||';'||maxCounter||';'||
		cast(firstTime as char format 'DD.MM.YY HH:MI:SS')||';'||cast(lastTime as char format 'DD.MM.YY HH:MI:SS');
     end
  end

--  for (select name from ip_analogdef where name like '__GD%' and name not like '%Diff%' order by 1) do
--     for (select min, max, avg from aggregates where name like local.name and ts between timeStart and timeEnd and period = timeEnd - timeStart) do
--        if ((min > FDmin and min < FDmax) or (max > FDmin and max < FDmax)) then
--           write name ||';min:;'||min||';max:;'||max||';avg:;'||avg;
--        end
--     end
--  end

end

if (runFD = 1) then
  SET OUTPUT 'C:\logs\FG-report-FD.csv';
  write 'Date:' || cast(current_timestamp as char format 'DD.MM.YY HH:MI:SS') || ';Report limits: '||FDmin||' <x< '||FDmax;
  write 'Tagname;Description;Counter1;Counter2;First;Last';

  for (select name, ip_description from ip_analogdef where (name like '__FD%' or name like '___FD%' or name like 'F3%DF%') and name not like '%FDI%' order by 1) do
     CheckTag(name, FDmax, FDmin);
     if (minCounter > 0) then
        write name ||';'||ip_description||';'|| minCounter||';'||maxCounter||';'||
		cast(firstTime as char format 'DD.MM.YY HH:MI:SS')||';'||cast(lastTime as char format 'DD.MM.YY HH:MI:SS');
     end
  end

--   for (select name from ip_analogdef where (name like '15FD%' or name like '15_FD%' or name like 'F3%DF%') and name not like '%FDI%' order by 1) do
--      for (select max, min, avg from aggregates where name like local.name and ts between timeStart and timeEnd and period = timeEnd - timeStart) do
--         if ((min > FDmin and min < FDmax) or (max > FDmin and max < FDmax)) then
--            write name ||';min:;'||min||';max:;'||max||';avg:;'||avg;
--         end
--      en
--   end
end

SET OUTPUT=DEFAULT;

SYSTEM '"C:\\source\\scripts\\fg-copy-report.bat"';

write 'Program ended:' || getdbtime;;
