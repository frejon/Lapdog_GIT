function []= an_outputscience(XXP)
global MISSING_CONSTANT;
global ASW_tabindex
ASW_tabindex=[];
CONT_macros=[516;525;610;611;613;615;617;624;816;817;900;901;903;904;905;916;926];
global VFLOATMACROS

debug=[0 0 0];
%warning on verbose

iph0conditions=[];
iph0conditions.I_Vb=-17.0;%V from generating lap1 vector.
iph0conditions.I_Vb_eps=1.0;%V epsilon, from generating lap1vector
iph0conditions.time_window=1*60*60;%s  time window
iph0conditions.time_samples=20;%minimum samples in time window
iph0conditions.samples=11;%Samples minimum.
iph0conditions.CONT = -1.51e-9;
%default value of CONT = +1.51e-9;
% for i= 1:XXP(1).info.nroffiles
%
%       t0 = cellfun(@(x) datenum(strrep(x,'T',' ')),XXP(i).data.Tarr(:,1));
%
%
% % end
% flds= {'data.t0' 'Iph0' 'Tph' 'Te_exp_belowVknee' 'Vph_knee' 'ni_aion'...
%     'Illumination' 'Vbar' 'Vph_knee_lowAc' 'Vbar_lowAc' 'Qualityfactor' ...
%     'asm_ion_slope' 'old_Vx' 'old_Vsi' 'Vsi' 'macroId' 'ion_slope' 'curr' 'B'...
%     'asm_ne_5eV' 'asm_ni_v_dep'};

dataflds= {'t0' 'ion_slope' 'curr' 'B' 'Iph0' 'lum' 'qf' 'macroId',}; %note, macroID is not actually in dataflds,but will be added to it in the struct_cleanup function
%dataflds= {'t0' 'ion_slope' 'curr' 'B' 'Iph0' 'lum' 'qf' 'macroId','VzP','Vz','Vph_knee'}; %note, macroID is not actually in dataflds,but will be added to it in the struct_cleanup function

%infoflds= {'macroId'};

if ~debug(1) %PHO.TAB
%PHO= struct_cleanup(XXP,infoflds,dataflds);
PHO= struct_cleanup(XXP,dataflds);

PHO= PHOTABFILE(PHO,iph0conditions,XXP);

end



for i = 1:XXP(1).info.nroffiles %AXP generation!
    len =length(XXP(i).data.qf);
    filename=XXP(i).info.file;
    filename(end-6:end-4)='ASW';

    folder = strrep(XXP(i).info.file,XXP(i).info.shortname,'');

    if ~debug(2)%ASW.TAB

    twID = fopen(filename,'w+');

    %quickfix for ASW
    if ismember(XXP(i).info.macroId,CONT_macros)
        XXP(i).data.Iph0(:,1)=XXP(i).data.Iph0(:,1)+iph0conditions.CONT;
    end
%     delind=find(isnan(XXP(i).data.Iph0(:,1)));
%     if ~isempty(delind)
%         for k=1:length(delind)
%             XXP(i).data.Iph0(delind(k),1)= MISSING_CONSTANT;
%         end
%     end
%
%

    %This line can generate strange error if MISSING_CONSTANT isn't
    %already well defined

    XXP(i).data.Iph0(isnan(XXP(i).data.Iph0(:,1)),1)=MISSING_CONSTANT;
    %fix contamination issues)

    
    % -----------------find shadowed  data  ----------------

    dark=XXP(i).data.lum<1;
    XXP(i).data.Vz(dark,1)=MISSING_CONSTANT;
    XXP(i).data.Vz(dark,2)=0;
    XXP(i).data.Vph_knee(dark,1)=MISSING_CONSTANT;
    XXP(i).data.Vph_knee(dark,2)=0;
    XXP(i).data.Iph0(dark,1)=MISSING_CONSTANT;
    XXP(i).data.Iph0(dark,2)=0;
    % -----------------find shadowed  data  ----------------

    

    path_to_mat_file='MIP_v23_forlapdog.mat';
    %    path_to_mat_file='MIP_v23_forlapdog.mat';
    XCAL_struct=XCAL_lapdog(XXP(i).data,path_to_mat_file);

    
    % -----------------find low temperature data  ----------------
    %ne_5eV= max((1e-6*sqrt(2*pi*CO.me*Te_guess) *e_slope / (IN.probe_A*CO.e.^1.5)),0)
    %ne_5eV(e_slope = 70nA/V) = 743.467535;
    %for reference of 70nA, see Engelhardt 2017

    cold_ind=XXP(i).data.asm_ne_5eV(:,1)> 743.467535;% find low temperature data    
    XXP(i).data.asm_ne_5eV(cold_ind,1)=XXP(i).data.asm_ne_5eV(cold_ind,1)*sqrt(0.1)/sqrt(5);
    
    % -----------------find low temperature data  ----------------




    %% Quality value handling!
    qv_Te_exp_belowVknee=exp(-XXP(i).data.Te_exp_belowVknee(:,2));
    delind=isnan(qv_Te_exp_belowVknee)|isinf(qv_Te_exp_belowVknee);
    qv_Te_exp_belowVknee(delind)=0;
%    qv_ionV=exp(-XXP(i).data.asm_ion_slope(:,2));
   % qv_Te_XCAL=exp(-XCAL_struct.frac_uncertainty.^2);
    qv_Te_XCAL= exp(-(XXP(i).data.asm_ne_5eV(:,2).^2+XCAL_struct.frac_uncertainty.^2));
    delind=isnan(qv_Te_XCAL)|isinf(qv_Te_XCAL);
    qv_Te_XCAL(delind)=0;

    qv_ionV=exp(-sqrt(XXP(i).data.asm_ion_slope(:,2).^2+XCAL_struct.frac_uncertainty.^2));
    %filt_thesemaybe= qv_ionV<0.5;
    delind=isnan(qv_ionV)|isinf(qv_ionV);
    qv_ionV(delind)=0;


    qv_asm_ne_5eV= exp(-XXP(i).data.asm_ne_5eV(:,2));
    qv_asm_ne_5eV(cold_ind)=0;
    delind=isnan(qv_asm_ne_5eV)|isinf(qv_asm_ne_5eV);
    qv_asm_ne_5eV(delind)=0;


    satur_ind=XXP(i).data.Vph_knee(:,1)~=MISSING_CONSTANT;

    %Sweep_qv_dir_and_step = (1-abs(XXP(i).info.diff_Vb-0.05))/0.81;% range best bias resolution, from 0 to 1. Good resolution but poor direction(negative) is a bit less good
    Sweep_qv_range = abs(XXP(i).info.Vb_length*XXP(i).info.diff_Vb/60);% range of sweep, from 0 to 1 (max), scalar
    Sweep_qv_signal=exp(-1./(abs((XXP(i).data.minmaxI(:,1)/4e-9))));%also from 0 (low signal-to noise ion current) to 1(high signal); vector scaled to 4nA
    qv_Vph_knee=min((Sweep_qv_range*Sweep_qv_signal)./(abs(XXP(i).data.Vph_knee(:,2).*XXP(i).data.Vph_knee(:,1))),1);%from 0 to 1, Vph_knee quality convolved with sweep quality
    %qv_Vphknee=min((1./abs(XXP(i).data.Vph_knee(:,2).*XXP(i).data.Vph_knee(:,1)))*Sweep_qv_range.*exp(-1./(abs(XP1.minmaxI(indz,1)/4e-9)))),1))
    %qv_Vphknee=((abs(XXP(i).data.Vph_knee(:,2).*XXP(i).data.Vph_knee(:,1))))


    if XXP(i).info.diff_Vb < 0.6 %worst resolution, 0.72V
        Sweep_qv_step=0.7;
    elseif XXP(i).info.diff_Vb < 0.4 %medium resolution, 0.48V,
        Sweep_qv_step=0.8;
    elseif XXP(i).info.diff_Vb < 0.2 %highest resolution, 0.24V
        Sweep_qv_step=1;
    elseif XXP(i).info.diff_Vb < -0.3 %highest resolution, 0.24V, shitty direction
        Sweep_qv_step=0.9;
    elseif XXP(i).info.diff_Vb < -0.6 %medium resolution, 0.48V, shitty direction
        Sweep_qv_step=0.8;
    else %Worst direction, worst resolution doesn't exist.
        Sweep_qv_step=0.6;
    end

    qv_Vph_knee=qv_Vph_knee*Sweep_qv_step;

    %qv_Vph_knee= exp(-XXP(i).data.Vph_knee(:,2));
    delind=isnan(qv_Vph_knee)|isinf(qv_Vph_knee);
    qv_Vph_knee(delind)=0;
    qv_Vph_knee(satur_ind)=Sweep_qv_signal(satur_ind)*Sweep_qv_range*Sweep_qv_step; % if shadowed, or otherwise. It can be nice to see the quality of the sweep.

%    figure(6);histogram((exp(-abs(300*error_ion_slope./XP1.Iph0(:,1)))),10000)

    error_ion_slope=XXP(i).data.ion_slope(:,2).*XXP(i).data.ion_slope(:,1);
    qv_iph0=exp((300*error_ion_slope./XXP(i).data.Iph0(:,1))); % was -1. but Iph0 is already minus. compare with histogram above.

    qv_iph0(qv_iph0>1 | qv_iph0<0)=0;

    qv_iph0_test = XXP(i).data.Iph0(:,1)./(XXP(i).data.minmaxI(:,1)); %this value should be between 0 and 1;


    %%    %filter values outside LAP range

    outside_range= XXP(i).data.Iph0(:,1)>0 | abs(qv_iph0_test)>1.01;
    %%positive photoemission is not good, also not good: Iph0 larger than
    %%most negative current in sweep.
    XXP(i).data.Iph0(outside_range,1)=MISSING_CONSTANT;
    qv_iph0(outside_range)=0;%qv
    delind=isnan(qv_iph0)|isinf(qv_iph0);
    qv_iph0(delind)=0;

    inside_range= XXP(i).data.Te_exp_belowVknee(:,1)>0 | XXP(i).data.Te_exp_belowVknee(:,1)<30;
    XXP(i).data.Te_exp_belowVknee(~inside_range,1)=MISSING_CONSTANT;
    qv_Te_exp_belowVknee(~inside_range)=0;%qv

    %out_of_valid_range=nansum(XCAL_struct.Te./XXP(i).data.Te_exp_belowVknee(:,1)>1) > 5;

    inside_range= XCAL_struct.Te>0 | XCAL_struct.Te<30;

    XCAL_struct.Te(~inside_range)=MISSING_CONSTANT;
    qv_Te_XCAL(~inside_range)=0;%qv
    

%     qv_iph0_2 =qv_iph0_test;
%     qv_iph0_2(:) = 0.2407/XXP(i).info.diff_Vb; % this is one, 0.5, 0.33, or 0.25;
%     qv_iph0_3(:) = exp(-XXP(i).info.diff_Vb*XXP(i).info.Vb_length/60);
%

     %qv_Te= exp
     %This is destructive, but is needed for NED.TAB files! I don't want to
     %redo these qv algorithms inside the ASW code.
     XXP(i).data.Vph_knee(:,2)=qv_Vph_knee;

     %%print ASW
     
    for j = 1:len

        %remember i & j !!!

        %data_arr.Tarr_mid{j,1}(1:23),data_arr.Tarr_mid{j,2}
       % str1=sprintf('%s, %s, %16.6f, %16.6f,',XXP(i).data.Tarr{j,:});
        str1=sprintf('%s, %16.6f,',XXP(i).data.Tarr_mid{j,:}); %XXP(i).data.Tarr_mid{j,1}<- UTC {j,2} <- OBT


        %str2=sprintf('%14.7e, %2.1f, %14.7e, %2.1f, %16.6f, %16.6f, %14.7e',dummy_ne,dummy_qv,XXP(i).data.Iph0(j,1),dummy_qv,dummy_v_ion,dummy_qv,XXP(i).data.Te_exp_belowVknee(j,1),dummy_qv,dummy_Te_XCAL,dummy_qv);

        str2=sprintf(' %14.7e, %4.2f,',XXP(i).data.asm_ne_5eV(j,1),qv_asm_ne_5eV(j));
        str3=sprintf(' %14.7e, %4.2f,',XXP(i).data.Iph0(j,1),qv_iph0(j));
        str4=sprintf(' %14.7e, %4.2f,',XCAL_struct.ionV(j),qv_ionV(j));
        str5=sprintf(' %14.7e, %4.2f,',XXP(i).data.Te_exp_belowVknee(j,1),qv_Te_exp_belowVknee(j));
        str6=sprintf(' %14.7e, %4.2f,',XCAL_struct.Te(j),qv_Te_XCAL(j));
        str7=sprintf(' %14.7e, %4.2f,',XXP(i).data.Vph_knee(j,1),qv_Vph_knee(j));
        str8=sprintf(' %03i',XXP(i).data.qf(j));

        strtot=strcat(str1,str2,str3,str4,str5,str6,str7,str8);
        row_bytes= fprintf(twID,'%s\r\n',strtot);
    end
    
    

    ASW_tabindex(end+1).fname = filename;                   % Start new line of an_tabindex, and record file name
    ASW_tabindex(end).fnameshort = strrep(filename,folder,''); % shortfilename
    ASW_tabindex(end).first_index = XXP(i).info.firstind; % First calib data file index
    ASW_tabindex(end).no_of_rows = len;                % length(foutarr{1,3}); % Number of rows
    ASW_tabindex(end).no_of_columns = 15;            % Number of columns
    % usc_tabindex{end,6] = an_ind(i);
    ASW_tabindex(end).type = 'ASW'; % Type
    ASW_tabindex(end).timing = XXP(i).info.timing;
    ASW_tabindex(end).row_byte = row_bytes;
    fclose(twID);


    fileinfo = dir(filename);
    if fileinfo.bytes ==0 %happens if the entire collected file is empty (all invalid values)
        %  if N_rows > 0 %doublecheck!
        delete(filename); %will this work on any OS, any user?
        ASW_tabindex(end,:) = []; %delete tabindex listing to prevent errors.
        % end

    else

    end





    end %debug(2)
    if ~debug(3)%USC.TAB
        if  any(ismember(dec2hex(XXP(i).info.macroId),VFLOATMACROS{1})) || any(ismember(dec2hex(XXP(i).info.macroId),VFLOATMACROS{2}))


        else% no Vfloat here, let's print Vz
            %if there's no vfloat measurements
            USCfname=filename;
            USCfname(end-6:end-4)='USC';
            USCshort = strrep(USCfname,folder,'');


            
            XXP(i).data.Vph_knee(:,2)=qv_Vph_knee;

            
            an_USCprint(USCfname,USCshort,NaN,XXP(i).data,XXP(i).info.firstind,XXP(i).info.timing,'vz');
            
            NEDfname=filename;
            NEDfname(end-6:end-4)='NED';
            NEDshort = strrep(NEDfname,folder,'');
            an_NEDprint(NEDfname,NEDshort,XXP(i).data,XXP(i).data.t0,XXP(i).info.firstind,XXP(i).info.timing,'vz');
            
            %NELfname=filename;
            %NELfname(end-6:end-4)='NEL';
            %NELshort = strrep(NELfname,folder,'');
            %data_arr=an_NELprint(NELfname,NELshort,XXP(i).data,XXP(i).data.t0,XXP(i).info.firstind,XXP(i).info.timing,'vz');

            

        end
    end



end




end



function resampled = PHOTABFILE(lapstruct,conditions,XXP)
%takes a SORTED struct with A1S fields, groups them and computes iph0 via
%niklas multi sweep method.
global PHO_tabindex
global MISSING_CONSTANT;

PHO_tabindex=[];

lapstruct= fixlap1_cont_iph0(lapstruct,conditions.CONT); % check for contamination & prepare output
an_diag = 0;

%niklas iph_calc.m revisited

resampled=[];
resampled.ind=[];
resampled.curr=[];
resampled.ion_slope=[];
resampled.conds=conditions;


%%%--------illumination check------------------------%%%
dynampath = strrep(mfilename('fullpath'),'an_outputscience','');
kernelFile = strcat(dynampath,'metakernel_rosetta.txt');
paths();

cspice_furnsh(kernelFile);




intval = resampled.conds.time_window;%seconds


%
% resampled.conds=[];
% resampled.conds.I_Vb=-17.0;%V from generating lap1 vector.
% resampled.conds.I_Vb_eps=1.0;%V epsilon, from generating lap1vector
% resampled.conds.time_window=2*60*60;%s  time window
% resampled.conds.time_samples=10;%minimum samples in time window
% resampled.conds.samples=10;%Samples minimum.
%
      %  UTCpart1= XXP(1).info.timing{1,1}(1:11);
        %UTCpart1 = scantemp{1,1}{1,1}(1:11);
      %  utc_str= XXP(1).timing{1,1};
      %  utc_str= XXP(1).info.timing{1,1};%this is start of file
        % utc_str=XXP(1).data.Tarr{1,1}; %this is start of first sweep data point, slightly different

        utc_str=cspice_et2utc(lapstruct.t0(1),'ISOC',10);


        % Set starting spaceclock time to (UTC) 00:00:00.000000
        ah= str2double(utc_str(12:13));
        am= str2double(utc_str(15:16));
        as= str2double(utc_str(18:end));

       % ah =str2double(scantemp{1,1}{1,1}(12:13));
       % am =str2double(scantemp{1,1}{1,1}(15:16));
       % as =str2double(scantemp{1,1}{1,1}(18:end)); %including fractions of seconds
        hms = ah*3600 + am*60 + as;
        %tday0=scantemp{1,2}(1)-hms; %%UTC and Spaceclock must be correctly defined
        t_obt0= str2double(XXP(1).data.Tarr{1,3})-hms; %%epoch UTC and Spaceclock must be correctly defined
        t_et0= lapstruct.t0(1)-hms; %%epoch, UTC and Spaceclock must be correctly defined

     %t0 is "et" time of each measurement (start of sweep)
     inter = 1 + floor((lapstruct.t0(:) - t_et0)/intval); %prepare subset selection to accumarray


startind=inter(1);
groupind=[];



rowcount=0;
%prepare array with a bit or function that adds unique & different
%qualityflags together
qf_array  = accumarray(inter,lapstruct.qf,[],@(x) frejonbitor(unique(x)));


%len=row; % row is incremented to max row nr, but incase I forget.
%for i=1:len
k=0;
%for i = inter(1):inter(end)
%sometimes lapstruct.t0 is not sorted...?
%t_etz=floor(t_et0+(intval* (min(inter):max(inter)))+0.5);%maybe slightly incorrect. ugh.
t_etz=t_et0-intval/2+(intval* (min(inter):max(inter)));%midpoint of interval

%                               ((1:3600*24/intval)-0.5)*intval


t_obt= t_obt0 -intval/2+(intval*(min(inter):max(inter)));%midpoint of interval
t_utc= cspice_et2utc(t_etz(:).'+0.5, 'ISOC', 10);% buffer up with 0.5 second, before UTC conversion, and then round to closest second later in function
t_matlab_date=nan(length(t_etz),1);
for i = 1:length(t_etz)
    t_matlab_date(i)=datenum(strrep(t_utc(i,:),'T',' '));
    %t_obtz(i) = sct2obt(cspice_sce2s(-226,cspice_str2et('2016-09-03T01:00:01.500')))-sct2obt(cspice_sce2s(-226,cspice_str2et('2016-09-03T01:00:02.500')))
    t_obt(i) = sct2obt(cspice_sce2s(-226,t_etz(i))); %convert from et to SCLK to OBT
end


  %  save ~/matlabdump_utc.mat t_utc t_matlab_date

for i = min(inter):max(inter) %main for loop

    k=k+1;
    indz=find(inter==i);


    %indz= resampled.ind(i,:); % a lot of extra zeroes in resampled.ind... need to get rid of them.
   % indz(indz==0)=[]; %array of grouped indices.
    if ~isempty(indz)
    colz=1:length(indz);

    %%single sweep method resampling

   % resampled.median.iph0(i)=nanmedian(lapstruct.Iph0(indz));
    %resampled.median.sigma_iph0(i)=nanstd(lapstruct.Iph0(indz));
    %resampled.mean.iph0(i)=nanmean(lapstruct.Iph0(indz));
    %resampled.mean.sigma_iph0(i)=nanstd(lapstruct.Iph0(indz));
    %%

    resampled.curr(k,colz)=lapstruct.curr(indz);
    curr= resampled.curr(k,colz).';
    %curr = lapstruct.curr(indz);
    resampled.ion_slope(k,colz)=lapstruct.ion_slope(indz,1);
    resampled.ion_slope_sigma(k,colz)=lapstruct.ion_slope(indz,2);
    ion_slope = resampled.ion_slope(k,colz).';
   % ion_slope = lapstruct.ion_slope(indz,1); %need non structure variables.
    resampled.t0(k,colz) = lapstruct.t0(indz);
    resampled.t_epochmean(k)=mean(resampled.t0(k,colz));
    resampled.t_epoch(k)=t_et0+intval*i;
    resampled.t_OBT(k) = t_obt0 + intval*i;
  %  resampled.macroId = mean(lapstruct.macroId(indz));

    %remove shadowed, and unrealistic ionslopes

    %delind=find((lapstruct.lum(indz)<0.9) | ion_slope <0 | isnan(ion_slope) | isnan(curr));
    delind=(lapstruct.lum(indz)<0.9) | ion_slope <0 | isnan(ion_slope) | isnan(curr);
    curr(delind)=[]; %delind is the indexes of the group of index indz which are invalid
    ion_slope(delind)=[];

    if ge(length(curr),resampled.conds.samples) %if length >= 10 e.g.

%         [P,S]= polyfit(ion_slope,curr,1);
%         %       p = polyfit(currprim,curr,1); %
%
%         rms_tmp = std(polyval(P,ion_slope)-curr);
%         %Remove outliers
%         %ind2 = find(abs(polyval(P,ion_slope)-curr) > 3.5*rms_tmp);
%



%        ind2 = (abs(polyval(P,ion_slope)-curr) > 3.5*rms_tmp) | (abs(ion_slope-nanmedian(ion_slope))>1*nanstd(ion_slope));
%         outlierind = (abs(curr-nanmedian(curr))> 3*nanstd(curr))| (abs(ion_slope-nanmedian(ion_slope))>1*nanstd(ion_slope));
%
%         %outliers indicate that the plasma and ion current changed
%         %substantially or that the ion_slope estimate was poorly made
%
%         curr(outlierind)=[];
%         ion_slope(outlierind)=[];
%
%        % pfit = polyfit(currprim,curr,1);
%
        % if  ge(length(curr),resampled.conds.samples)
           %[P2,S2]= polyfit(ion_slope,curr,1);
           %warning off MATLAB:polyfit:RepeatedPointsOrRescale;
           [P2, outliers,S2] = fit_ols_ESD(ion_slope, curr); %new fitting routine with outlier removal.

           resampled.P(k,1:2) = P2;
           %resampled.S(i) = S2;
      % end


      if an_diag

          figure(2001);plot(ion_slope,curr,'o',ion_slope,polyval(P2,ion_slope),ion_slope,polyval(polyfit(ion_slope,curr,1),ion_slope),'-b')
          ax=gca;
          legend('data','fit OLS ESD','polyfit')
          ax.XLabel.String='ion slope [A/V]';
          ax.YLabel.String='current [A]';
          hline(P2(2),'-','Iph0');
          grid on;


      end



        %if too few points remain after outlier removal, or the slope is
        %unphysical, enter nan values. else:
        if ge(length(curr(~outliers)),resampled.conds.samples) && P2(1) < 0 %; %if length >= 10 e.g.
        %if ge(length(curr),resampled.conds.samples) && P2(1) < 0 %; %if length >= 10 e.g.


            resampled.iph0(k) = P2(2);% this is apparently iph0.
            try
                %S2.sigma = sqrt(diag(inv(S2.R)*inv(S2.R')).*S2.normr.^2./S2.df);
                resampled.iph0_sigma(k) = S2.sigma(2);

            catch err %horrible try catch.
                resampled.iph0_sigma(k) = nan;
            end

            %resampled.iph0_sigma(i) = S2.sigma(2);
        else
            resampled.iph0(k) = MISSING_CONSTANT;% fill with nan.
            resampled.iph0_sigma(k) = nan;

        end

    else

        resampled.iph0(k) = MISSING_CONSTANT;% fill with nan.
        resampled.iph0_sigma(k) = nan;
        resampled.P(k,1:2) = nan;

    end


    %% add to file





    end


    dirY = datestr(t_matlab_date(k),'YYYY');
    dirM = upper(datestr(t_matlab_date(k),'mmm'));
    dirD = strcat('D',datestr(t_matlab_date(k),'dd'));

%    dirY = datestr(resampled.t_epoch(k),'YYYY');
%    dirM = upper(datestr(resampled.t_epoch(k),'mmm'));
%    dirD = strcat('D',datestr(resampled.t_epoch(k),'dd'));
    folder = strcat(XXP(1).info.derivedpath,dirY,'/',dirM,'/',dirD,'/');

    filename = sprintf('%sRPCLAP_%s_000000_60M_PHO.TAB',folder,datestr(t_matlab_date(k),'yyyymmdd'));
%
%
%     if k>1 && ~strcmp(datestr(resampled.t_epoch(k-1),'dd'), datestr(resampled.t_epoch(k),'dd')) %%new calendar day? (won't check j==1)
%         %   newfile =false;
%         twID = fopen(filename,'w');
%
%     PHO_tabindex(end+1).fname = filename;                   % Start new line of an_tabindex, and record file name
%     PHO_tabindex(end).fnameshort = strrep(filename,folder,''); % shortfilename
%     %PHO_tabindex(end).first_index = index_nr_of_firstfile; % First calib data file index
%     PHO_tabindex(end).no_of_rows = rowcount;                % length(foutarr{1,3}); % Number of rows
%     PHO_tabindex(end).no_of_columns = 5;            % Number of columns
%     % usc_tabindex{end,6] = an_ind(i);
%     PHO_tabindex(end).type = 'USC'; % Type
%     PHO_tabindex(end).timing = timing;
%     PHO_tabindex(end).row_byte = row_byte;
%
%         rowcount=0;
%
%     else
%         twID = fopen(filename,'a+'); %new file.
%     end
%    % utc= cspice_et2utc(resampled.t_epoch(k), 'ISOC', 6);
%
%    % row_byte= fprintf(twID,'%s, %16.6f, %14.7e, %3.1f, %05i', utc, resampled.t_OBT(k), resampled.iph0(k),dummy_qv,qf_array(k));
%
%
    if ~(exist(folder,'dir')~=7) %folder doesn't exist, we've gone outside of archive




        if k>1 && strcmp(datestr(t_matlab_date(k-1),'yyyymmdd'), datestr(t_matlab_date(k),'yyyymmdd')) %%same calendar day? (won't check k==1)


            twID = fopen(filename,'a+'); %append to old file.
           %fprintf(1,'a+ opening file: %s\r\n',filename)

        else
            fclose('all') ; %close old file

            twID = fopen(filename,'w'); %open a new file, filename is now a different string.
           % fprintf(1,'w+ opening file: %s\r\n',filename)
            rowcount=0;

            PHO_tabindex(end+1).fname = filename;                   % Start new line of an_tabindex, and record file name
            PHO_tabindex(end).fnameshort = strrep(filename,folder,''); % shortfilename
            %PHO_tabindex(end).first_index = index_nr_of_firstfile; % First calib data file index
            PHO_tabindex(end).no_of_columns = 5;            % Number of columns
            % usc_tabindex{end,6] = an_ind(i);
            PHO_tabindex(end).type = 'PHO'; % Type
            %PHO_tabindex(end).timing = timing;
        end


        if (isempty(indz) && (rowcount>0))   % nothing here & file open. fill with MISSING_CONSTANT
           % t_utc(end-8:end)='59.999797';
           % t_utc(k,end-8:end)='00.000000';
            t_utc(k,21:26)='000000';%increased UTC precision, now we need to floor away this 0.5s margin
            %t_utc is now a string with more than 6 decimals precision, but we
            %force the output to only print the first 6.
            fprintf(twID,'%s, %16.6f, %14.7e, %4.2f, %03i\r\n', t_utc(k,1:26), t_obt(k), MISSING_CONSTANT,0,qf_array(k));
            rowcount=rowcount+1;

        elseif (~isempty(indz))
            %t_utc(k,end-8:end)='00.000000';
            t_utc(k,21:26)='000000'; %increased UTC precision, now we need to floor away this 0.5s margin
            %t_utc is now a string with more than 6 decimals precision, but we
            %force the output to only print the first 6.
            if resampled.iph0(k)==MISSING_CONSTANT
                pho_60M_qv=0;
            else
                pho_60M_qv= exp(-abs(resampled.iph0_sigma(k)/resampled.iph0(k)));
            end
            
            
            %row_byte= fprintf(twID,'%s, %16.6f, %14.7e, %3.1f, %05i\r\n', t_utc(k,:), resampled.t_OBT(k), resampled.iph0(k),dummy_qv,qf_array(k));
            row_byte= fprintf(twID,'%s, %16.6f, %14.7e, %4.2f, %03i\r\n', t_utc(k,1:26), t_obt(k), resampled.iph0(k),pho_60M_qv,qf_array(k));

            rowcount=rowcount+1;
            PHO_tabindex(end).no_of_rows = rowcount;                % length(foutarr{1,3}); % Number of rows
            PHO_tabindex(end).row_byte = row_byte; %will repeatedly get overwritten until  PHO_tabindex(end+1).fname = filename;        is called
            %PHO_tabindex(end).timing{3} = resampled.tO(k);
%        timing={scantemp{1,1}{1,1},scantemp{1,1}{end,1},scantemp{1,2}(1),scantemp{1,2}(end)};

        else
            %first file in array, no valid points.

        end





    end%folder doesn't exist, we've gone outside of archive

%         if(~isempty(indz))  % Print values!
%
%             row_byte= fprintf(twID,'%s, %16.6f, %14.7e, %4.2f, %05i', utc, resampled.t_OBT(k), resampled.iph0(k),dummy_qv,qf_array(k));
%             rowcount=rowcount+1;
%         else % nothing here. fill with MISSING_CONSTANT
%             row_byte= fprintf(twID,'%s, %16.6f, %14.7e, %3.1f, %05i', utc, t_obtz(k), MISSING_CONSTANT,0,qf_array(k));
%             rowcount=rowcount+1;
%
%
%         end%print value or NaN

end%main loop


%% clean up empty files
delindz=[];
for i = 1:length(PHO_tabindex)%clean up empty files


    D= dir(PHO_tabindex(i).fname);

    if (D.bytes==0 ||PHO_tabindex(i).no_of_rows == 0)

        %    if PHO_tabindex(i).no_of_rows == 0
        %D= dir(PHO_tabindex(i).fname);

        fprintf(1,'%s size is %i \n',PHO_tabindex(i).fname,D.bytes);
        delete(PHO_tabindex(i).fname);
        delindz=[delindz;i];


    end
end

PHO_tabindex(delindz)=[];
%%
 cspice_kclear;

end%function

function lapstruct_fixed = fixlap1_cont_iph0(lapstruct,CONT)
%default value of CONT = +1.51e-9;

% old_iph0.Vbias(ind)=  +20;%          515
% old_iph0.Vbias(ind)=+30;%          516
% old_iph0.Vbias(ind)=+30;%          525
% old_iph0.Vbias(ind)=  +20;%          604
% old_iph0.Vbias(ind)=+30;%          610
% old_iph0.Vbias(ind)=+30;%          611
% old_iph0.Vbias(ind)=+30;%          613
% old_iph0.Vbias(ind)=+30;%          615
% old_iph0.Vbias(ind)=+30;%          617
% old_iph0.Vbias(ind)=+30;%          624
% old_iph0.Vbias(ind)=+30;%          816
% old_iph0.Vbias(ind)=+30;%          817
% old_iph0.Vbias(ind)=+30;%          900
% old_iph0.Vbias(ind)=+30;%          901
% old_iph0.Vbias(ind)=+30;%          903
% old_iph0.Vbias(ind)=+30;%          904
% old_iph0.Vbias(ind)=+30;%          905
% old_iph0.Vbias(ind)=+30;%          916
% old_iph0.Vbias(ind)=+30;%          926
lapstruct_fixed=lapstruct;

cont_macros=[516;525;610;611;613;615;617;624;816;817;900;901;903;904;905;916;926];


ind=ismember(lapstruct.macroId,cont_macros);

lapstruct_fixed.Iph0(ind)=lapstruct_fixed.Iph0(ind)+CONT;
lapstruct_fixed.curr(ind,:) = lapstruct.curr(ind,:)+CONT;

end

%function lapfile= struct_cleanup(dataraw,infofields,datafields)
function lapfile= struct_cleanup(dataraw,datafields)

%lapfile takes a horrible massive struct called dataraw from readAxS_prelim
% and polishes, removing any struct field that is not named in the "flds"
% parameter list. The code was made to output averages and medians per file
% as well.
% if the flds listed do not contain "B" or "curr" then
% lapfile_with_iph0_niklas will not work

%infolenflds = length(infofields);
datalenflds = length(datafields);

%lenI = length(fldI);

lapfile=[];
% meand1=[];
% mediand1=[];
std1=[];
%std=[];
%
% for j=1:length(dataraw)
%
%     if ~isempty(dataraw(j).strID)
%
%         lapfile.strID=dataraw(j).strID;
%         break; %exit loop early when we find a value that is not erroneous, we only need one.
%     end
% end


for j=1:length(dataraw)

    %first, map XXP.info.macroID to XXP.data.macroID.
   len_d=length(dataraw(j).data.qf);
   dataraw(j).data.macroId(1:len_d,1)=dataraw(j).info.macroId;




  %  j
    if j <2

%
%         for k=1:infolenflds
%             lapfile.(sprintf('%s',infofields{1,k})) =[dataraw(j).info.(sprintf('%s',infofields{1,k}))];
%
%         end
%

        for k=1:datalenflds
            lapfile.(sprintf('%s',datafields{1,k})) =[dataraw(j).data.(sprintf('%s',datafields{1,k}))];

        end

           lapfile.Tarr=dataraw(j).data.Tarr; %special case for this parameter


    else

          lapfile.Tarr=vertcat(lapfile.Tarr, dataraw(j).data.Tarr); %special case for this parameter

%
%
%         for k=1:infolenflds
%           lapfile.(sprintf('%s',infofields{1,k})) = [ [lapfile.(sprintf('%s',infofields{1,k}))] ; [dataraw(j).info.(sprintf('%s',infofields{1,k}))] ];
%
%
%        end
        for k=1:datalenflds
           lapfile.(sprintf('%s',datafields{1,k})) = [ [lapfile.(sprintf('%s',datafields{1,k}))] ; [dataraw(j).data.(sprintf('%s',datafields{1,k}))] ];


        end








    end


end

%lapfile.mean=meand1;
%lapfile.median=mediand1;

end


function XCAL_L= XCAL_lapdog(LAP,path_to_matfile)
global MIP %change to persistent later
global CO IN MISSING_CONSTANT assmpt


pseudo_int_treshold=2.5e-1; %to filter out most unimportant MIP measurements. Some others will be removed later
%%% below no longer valid -FKJN 21/9. Forgot about split sweeps
%%% 2e-3 WORKssome arbitrary limit, looks good enough.
% a limit of 2e-3 WORKS, but we can increase it slightly to be sure.
%1e-3  makes us miss 4 points within 1 second.


XCAL_L=[];
XCAL_L.ionV=LAP.t0;
XCAL_L.ionV(:)=MISSING_CONSTANT; %default to missing constant

XCAL_L.t0=XCAL_L.ionV;
XCAL_L.t0(:)=nan; %default to nan, for debug plotting
XCAL_L.mipnefilt = XCAL_L.ionV;
XCAL_L.Te= XCAL_L.ionV;
XCAL_L.frac_uncertainty= XCAL_L.ionV(:);
XCAL_L.mipnefilt= XCAL_L.ionV(:);


if isempty(MIP)

load(path_to_matfile,'MIP'); %loads MIP variable from file

end




assmpt=[];
assmpt.ionM=19;%a.u.
assmpt.vram=550;%m/s

% try
%     preamble;
% catch err
% end
%
% delind=isnan(MIP.ne);
%
% MIP.tt(delind)=[];
% MIP.ne(delind)=[];




len = length(LAP.t0);

if len ~=1
    pseudo_ind = interp1(LAP.t0,1:len,MIP.tt);
else    %special case for len == 1, for which interp1 can't handle

    [diff,closest_mip]=min(abs(LAP.t0-MIP.tt));
    pseudo_ind=ones(1,length(MIP.tt))+0.5; %silly vector all filled with 1.5's everywhere

    if diff > pseudo_int_treshold       %exit early?
        return;
    else
            pseudo_ind(closest_mip)=1; % filt_inds thing should be able to find this if it exists.
    end


end

%pseudo ind interpolates
%indzz=abs(shit-floor(shit+0.5))< 2e-3; %some arbitrary limit, looks good enough.
filt_inds=abs(pseudo_ind-floor(pseudo_ind+0.5))< pseudo_int_treshold;
%%% below no longer valid -FKJN 21/9. Forgot about split sweeps
%%% 2e-3 WORKssome arbitrary limit, looks good enough.
% a limit of 2e-3 WORKS, but we can increase it slightly to be sure.
%1e-3  makes us miss 4 points within 1 second.

XCAL_M=[];
XCAL_M.mipnefilt=MIP.ne(filt_inds);
XCAL_M.frac_uncertainty=MIP.frac_uncertainty(filt_inds);
%XCAL_M.mipID=MIP.ID(filt_inds);
XCAL_M.t1=MIP.tt(filt_inds);
XCAL_M.lapind=nan(1,length(XCAL_M.t1)); %default to nan, useful later
XCAL_M.ionV             =nan(length(XCAL_M.t1),1);
XCAL_M.Te               =nan(length(XCAL_M.t1),1);
XCAL_M.t_dur=MIP.t_dur(filt_inds);
%XCAL.t1 = LAP.t1;


pts_to_check=pseudo_ind(filt_inds);
%indz=[];

if isempty(pts_to_check)
    return;
end

for i = 1:length(pts_to_check)

    lap_ind=floor(pts_to_check(i)+0.5);
    if min(abs(LAP.t0(floor(pts_to_check(i)+0.5))-XCAL_M.t1(i)))>max(1,XCAL_M.t_dur(i))
        %'shit'
         % indz=vertcat(indz,i);
        %fprintf(1,'diff is %d sec k=%d, i = %d \n',abs(LAP.t1(floor(pts_to_check(i)+0.5))-XCAL.t1(i)),k,i);
    else

   XCAL_M.ionV(i) = XCAL_M.mipnefilt(i)*2*IN.probe_cA*(CO.e).^2/(assmpt.ionM*CO.mp*LAP.asm_ion_slope(lap_ind,1)*1e-6);
   XCAL_M.Te(i) = 5* (XCAL_M.mipnefilt(i)/LAP.ne_5eV(lap_ind)).^2;
   XCAL_M.lapind(i) =floor(pts_to_check(i)+0.5);%
    end

end




delind =isnan(XCAL_M.ionV)|isinf(XCAL_M.ionV)|XCAL_M.ionV==0;
XCAL_M.ionV(delind)=MISSING_CONSTANT;
delind =isnan(XCAL_M.Te)|isinf(XCAL_M.Te)|XCAL_M.ionV==0;
XCAL_M.Te(delind)=MISSING_CONSTANT;

%change to XCAL_L with LAP indexing, instead of MIP indexing

indz=find(~isnan(XCAL_M.lapind(:))); %

XCAL_L.ionV(XCAL_M.lapind(indz))            =XCAL_M.ionV(indz);
XCAL_L.t0(XCAL_M.lapind(indz))              =XCAL_M.t1(indz);
XCAL_L.Te(XCAL_M.lapind(indz))              =XCAL_M.Te(indz);
%I care less about these, so some values will be empty.
%XCAL_L.mipID(XCAL_M.lapind(indz))           =XCAL_M.mipID(indz);
XCAL_L.frac_uncertainty(XCAL_M.lapind(indz)) =XCAL_M.frac_uncertainty(indz);
XCAL_L.mipnefilt(XCAL_M.lapind(indz))       =XCAL_M.mipnefilt(indz);



end
