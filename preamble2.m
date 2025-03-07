% preamble.m -- set PDS keywords etc

% Should geometry files be exported to the archive?
export_geometry = input('Export geometry files to archive? (0/1) ');

% Set up automatic ssh login on vroom.umea.irf.se (assumes you have generated a
% public rsa key in your .ssh directory on squid and copied it to the known_hosts
% file in your .ssh directory on vroom)
% This will ask you for your ssh password once per session, instead of 
% twice per day in the archive... 

if(~exist('ssh_ok'))
  unix('eval `ssh-agent`');
  unix('ssh-add ~/.ssh/id_dsa');
  unix('ssh-add -l');
  ssh_ok = 1;
end

% Read mission calendar:
% (this path should really be dynamically read from user's pds.conf file)
missioncalendar = '/usr/local/src/gse/pds/Mission_Calendar.txt';
fc = fopen(missioncalendar,'r');
line = fgetl(fc);
jj = 0;
while((jj<100) & isempty(strfind(line,shortphase)))
  line = fgetl(fc);
  jj = jj + 1;
end
parts = textscan(line,'%s %s %*s %*s %s %s %s %s','delimiter',':');
% Need to remove double quotes and trailing blanks from strings (strrep, strtrim)
missionphase = strtrim(strrep(char(parts{1}),'"',''));
targetfullname = strtrim(strrep(char(parts{3}),'"',''));
targetid = strtrim(strrep(char(parts{4}),'"',''));
targettype = strtrim(strrep(char(parts{5}),'"',''));
target = strtrim(strrep(char(parts{6}),'"',''));

% Special for solar wind, which is not defined as a target in SPICE:
% aie 130313
if(target == 'SW')
  target = 'SUN';
end

% Read info from DATASET.CAT:
dname = strcat(archivepath,'/CATALOG/DATASET.CAT'); 
dp = fopen(dname,'r');
datasetcat = textscan(dp,'%s %s','Delimiter','=');
fclose(dp);
var = cellstr(char(datasetcat{1}));
val = char(datasetcat{2});
ind = find(strcmp('DATA_SET_NAME',var));
datasetname = strtrim(strrep(val(ind,:),'"',''));
ind = find(strcmp('DATA_SET_ID',var));
datasetid = strtrim(strrep(val(ind,:),'"',''));
tmp = textscan(datasetid,'%*s %*s %*s %d %*s %*s %*s', 'delimiter','-');
processlevel = tmp{1};

% archiveid is used internally for keeping track of index files. It is not a PDS thing.
archiveid = sprintf('%s_%d',shortphase,processlevel);

% End of preamble.m 
