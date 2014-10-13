%Example of Visual Plot use 
%
%This will plot a range estimation of a terrestial navigation system (Locata\pseudolite)
%assuming varied level of multipath/noise severity
%after my PhD thesis (see also roof_experiment_calculus.m)
%LKB 2012-14

clc;clear all;close(findall(0,'Type','figure'));
dbstop if error
% dbstop at 72 in VisualPlot
% dbstop at 107
dbstatus
tic;

%% INPUT DATA HERE
EarthRadius = 6378137; %[m] WGS84 semimajor axis
distance = 1:1:20000; %[m] [0-20km]
height = 1:0.001:35; %[m] ht over the surroundings
cable_lenght = 4; %[m]

LLTransmisionPower = [23 40]; %[dBm] %maxSysPowerNow(0xB) ; WhiteSands %-10:3:23
LLTrasmitterHt= [10,200]; %50:50:200];
 
%constants
Constant.Colour = ['r' 'g' 'b' 'k' 'c' 'm' 'y'];
Constant.PlotName ='04_SysRange';
Constant.PlotResolution=500;
BgColor='w';

Constant.LLMinReceivePower = -100; %[dBm] what is the min power for LL
%freq for Locata (Sx) and GPS (Lx)
Constant.S1 = 2412.28*10^6;
Constant.S6 = 2465.43*10^6;
Constant.L1 = 1575.42*10^6; % L1
Constant.L2 = 1227.6*10^6; % L2
Constant.c = 299792458;
Constant.L1_len = Constant.c/Constant.L1;
Constant.S1_len = Constant.c/Constant.S1;
Constant.S6_len = Constant.c/Constant.S6;

%% equations
dBmtomWatt = inline('10.^(dBm./10)','dBm'); %in dBm out mWatt
mWatttodBm = inline('10.*log10(Watt)','Watt'); %in mWatt out dBm 
%PROPAGATION MODELS
%open air model
FSPL = inline('20*log10(4*pi()*distance/SignalLenght)','distance','SignalLenght');
%simple MP model
% SMPSPL = inline('20*log10(distance.^2./(ht_trans.*ht_rov))','distance','ht_trans','ht_rov');
SMPSPL = inline('20*log10((2*pi()*distance.^3)./(SignalLenght*ht_trans.*ht_rov))',...
   'distance','ht_trans','ht_rov','SignalLenght');
%COST-231 Okuma-Hata models for large urban city (typical European ones!) 
%its not intended for 2.4 but for 2.0!!!
COST231PL = inline('46.4+33.9*log10(freq)-13.82*log10(ht_trans)+(44.9-6.55*log10(ht_trans))*log10(distance)+3.2*(log10(11.75*ht_rov)^2)-1.97',...
   'distance','ht_trans','ht_rov','freq');
%model for wireless transmission
ECC33PL = inline('20.41+100.294*log10(freq)+29.83*log10(dist)+95.6*(log10(freq).^2)-13.958*log10(ht_trans./200)-5.8*(log10(dist).^2)-(42.57+13.7*log10(freq)).*(log(ht_rov)-0.585)',...
   'dist','ht_trans','ht_rov','freq');
%visibility span, calculate eyesight (how far is is horizon)
VisSpan = inline('sqrt(ht.^2+2*ht*EarthRad)','ht','EarthRad');
VisSpan_acos = inline('EarthRad*acos(EarthRad./(EarthRad+ht))','ht','EarthRad');
%Curvature of the ray path correction
CvCorr = inline('(dist.^3)/(43*EarthRad^2)','dist','EarthRad');

%% PLOT ONE

HW_ScrSize = get(0,'ScreenSize');
figure('Color','white','MenuBar','none','Position',[0 0 HW_ScrSize(3) HW_ScrSize(4)]);
DistCorrection = CvCorr(distance,EarthRadius)*1000; %in mm
Mask=DistCorrection>0.5;
valX = distance(Mask)/1000;
DistCorrection=DistCorrection(Mask);
    subplot(2,1,1);
    hold on;  
    plot(valX,DistCorrection,'color','b','LineWidth',2);
    TickAcc=[3,1];
    XRange=[valX(1) valX(end)];
    XStrech = get(gca,'XLim'); XStrech(2)=XRange(2);
    YRange=[DistCorrection(1) DistCorrection(end)];
    TitleString = 'Earth curvature correction (equation is valid for distances up to 100km)';
    VisualPlot(gca,XRange,YRange,TitleString,'Range [km]',...
       'Curvature correction [mm]',XStrech,true,BgColor,TickAcc);

    hold off

% Pythagoras eq is very good simplification here
% VisibilitySpan=VisSpan(height,EarthRadius); 
VisibilitySpanAcos=VisSpan_acos(height,EarthRadius);
VisibilitySpanAcos=VisibilitySpanAcos/1000; %in km
Mask=(VisibilitySpanAcos>=10 & VisibilitySpanAcos<=20);
%     LegendStr = ['Pythagoras equation (simplified)'; 'Cosinus theorem (spherical)      '];	
    subplot(2,1,2);
    hold on;  
    plot(VisibilitySpanAcos,height,'color','b','LineWidth',2);
    TitleString = 'Distance to the apparent horizon';
    TickAcc=[3,2];
    XRange=[10 XRange(end)]; %match other plot
%     XStrech= [0 XRange(end)]; same as last time
    YRange=height(Mask);
    YRange=[YRange(1) YRange(end)];
    VisualPlot(gca,XRange,YRange,TitleString,'Distance to the apparent horizon [km]',...
       'Rover height over surrounding area [m]',XStrech,true,BgColor,TickAcc);

    hold off
screen2print([Constant.PlotName '_plot1'],Constant.PlotResolution); %save plots to *.jpg

 %% PLOT TWO
%Free space path loss

HW_ScrSize = get(0,'ScreenSize');
figure('Color','white','MenuBar','none','Position',[0 0 HW_ScrSize(3) HW_ScrSize(4)]);

subplot(2,1,1);
hold on;
txtLoc= 12000; %m
SignalLoss = FSPL(distance,Constant.S1_len);
val=distance/1000; %km
    plot(val,-SignalLoss,'color','b','LineWidth',3);
    PlaceLegend('Free Space Model (direct signal)',val(txtLoc),-SignalLoss(txtLoc),1,2); 
    YRange= [min(-SignalLoss) max(-SignalLoss);0 -999];
    YLim=get(gca,'YLim');
    for idx = 1:size(LLTrasmitterHt,2)
       txtAttr=idx~=1;
       if txtAttr
          plotCol='g';
          txtOffset=-4;
       else
          plotCol='r';
          txtOffset=-7;
       end;
       
       res = - SMPSPL(distance,LLTrasmitterHt(idx),1,Constant.S1_len);
       res(res>0)=NaN; %calculus error
       plot(val,res,'color',plotCol,'LineWidth',2);
       PlaceLegend(sprintf('LL Fading multipath ,LL_h_t=%3.0fm',LLTrasmitterHt(idx)),...
                   val(txtLoc),res(txtLoc),txtAttr,txtOffset); 
                   YRange(2,1)= min(YRange(2,1),min(res));
                   %YRange(2,2)=max(YRange(2,2),max(res));
                   
       %res = - SMPSPL(distance,LLTrasmitterHt(idx),1,Constant.L1_len);
      %just small diff between this and LL
                   
      if idx==size(LLTrasmitterHt,2) %just the last plot
          res = - COST231PL(distance*10^-3,LLTrasmitterHt(idx),1,Constant.S1*10^-6);
          plot(val,res,'color','c','LineStyle',':','LineWidth',2);
                  PlaceLegend(sprintf('COST231(GPS),LL_h_t=%3.0fm',LLTrasmitterHt(idx)),...
                   val(txtLoc),res(txtLoc),0,txtOffset);
                   %YRange(2,1)= max(YRange(2,1),min(res));
                   YRange(2,2)=max(YRange(2,2),min(res));

          res = - ECC33PL(distance*10^-3,LLTrasmitterHt(idx),1,Constant.S1*10^-9);
          res(res>0)=NaN; %calculus error
          plot(val,res,'color','m','LineStyle','--','LineWidth',2);
          PlaceLegend(sprintf('ECC33(LL),LL_h_t=%3.0fm',LLTrasmitterHt(idx)),...
                      val(txtLoc),res(txtLoc),0,txtOffset);
                   %this is same as FSL so lets correct first val
                      YRange(1,1)= max(YRange(1,1),min(res));
                      YRange(1,2)=max(YRange(1,2),max(res));
       end
    end
    TitleString = 'Signal path loss for receiver located 10m or 200m above ground and transmitting in S6 frequency with 23dBm';
    TickAcc=[2,0];
    XRange=[0 XRange(end)]; %match other plot
    [OrgAxis NewAxis]=VisualPlot(gca,XRange,YRange,TitleString,'Distance traveled by the signal [km]',...
       'Multipath loss [dB]',XRange,false,BgColor,TickAcc);
    ylabel(NewAxis(1),'Direct Loss [dB]')
    hold off

    subplot(2,1,2);
       YRange=[Constant.LLMinReceivePower -9999];
       XRange(1)=XRange(2);
    txtLoc= 4000; %m
    hold on;
    for idx = 1:size(LLTransmisionPower,2)
       %ReceivedPowerClean
       res = LLTransmisionPower(idx)-SignalLoss;
          %cut data under threshold
          Mask=res<Constant.LLMinReceivePower;
          res(Mask) = NaN;  
          tmp=val(~Mask); XRange(1)=min(XRange(1),tmp(end));
          plot(val,res,'color','g','LineWidth',2);
          PlaceLegend(sprintf('%3.0fdBm [%3.2fW]',LLTransmisionPower(idx),dBmtomWatt(LLTransmisionPower(idx))/10^3)...
             ,val(txtLoc),res(txtLoc),1,2); 
          YRange(1)=max(YRange(1),res(end));

%           %cut data under threshold
%           res(res<Constant.LLMinReceivePower) = NaN;

    end
 
   TitleString ='Locata range in a clean enviroment';
   TickAcc=[2,2];
   XStretch=[0 XRange(end)]; %match other plot
%    XRange=[val(end) XRange(end)];
   tmp=get(gca,'YLim');
   YRange(2)=tmp(2);
   PlaceLegend(sprintf('Min decoding power %2.0fdBm [%3.2EW]',Constant.LLMinReceivePower,...
      dBmtomWatt(Constant.LLMinReceivePower)/10^3),XRange(1),Constant.LLMinReceivePower,1,4); 
      
   XRange=[0 10;XRange];
   [OrgAxis NewAxis]=VisualPlot(gca,XRange,YRange,TitleString,'Distance to the rover [km]',...
    'Signal strenght [dBm]',XStretch,false,BgColor,TickAcc);
   xlabel(NewAxis(end-1),'Distance to the rover [km]');
   title(NewAxis(end-1),TitleString,'FontSize',get(0,'defaultaxesfontsize')+2);
   title(NewAxis(end),'');
    hold off
screen2print([Constant.PlotName '_plot2'],Constant.PlotResolution); %save plots


 %% PART THREE
%Range of the Network
%Constant.LLRange = 10 ; %[km]
%assume that we work on average of 80% capacity
%whole area can be defined as equal length squares (2xtriangles)

    
 %% EOF
toc;
%MAIN BODY ends here


