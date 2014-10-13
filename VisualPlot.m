% this is a part of my clean graph effort to create pleasant figures
%XRange,YRange defines marked range (one to be marked) [start end] can be mulitple , just add extra rows
%XStretch define TRUE range (data range), if not defined or empty then existing range to be used
%if XRange,YRange=[] no corr will be carried out, GridOn plots grid(X only)
% if Title='' no title ploted
%TickAcc=[XTickAcc YTickAcc] display acc
%returns handle to orginal plot and handles to all new axis (Y then X)
%LKB 2012(c)
%no error checks

function [OrgAxis NewAxis]=VisualPlot(OrgAxis,XRange,YRange,Title,XLabel,YLabel,XStretch,GridOn,BgColor,TickAcc)

NewAxis=[];
DefaulTextSize = get(0,'defaultaxesfontsize');
box off;
grid off;

%time for some max play, I only max X axis as Y is usually ok
try
	OrginalRange = get(gca,'XLim');
% 	OrginalPos = get(gca,'Position');
	if (exist('XStretch','var') && ~isempty(XStretch))  %(XLimMax~=0)
		set(gca,'XLim',[XStretch(1) XStretch(end)]); %just in case somebody throw an array
   else
      XStretch=get(gca,'XLim');
	end;
catch exception
		sprintf('Error! XLimMax=[%i %i] Sys said: %s\nI will try to recover and use orginal settings.',...
		XStretch(1),XStretch(end),exception.message);
		set(gca,'XLim',OrginalRange);
	   %Error_msg = []
%        display(Error_msg);
     %return  
end

%IF WE DONE EQ AXIS WE CANT PLAY WITH AXIS ANYMORE !!!
% EqualAxis=get(OrgAxis,'DataAspectRatio');
% EqualAxis=sum(EqualAxis)/size(EqualAxis,2);
% if EqualAxis~=1 %OK WE CAN PLAY
	%create dummy plot with all data to get range correct
	ylabel(YLabel);
	xlabel(XLabel);
	if ~isempty(Title)
		title(Title,'FontSize',DefaulTextSize+2);
	end
	TicksLabel=TicksLabeltfromTicks(get(gca,'YTick'),TickAcc(2));
	set(gca, 'YTickLabel',TicksLabel)
	[Ticks TickLabel]=GetTicks(get(gca,'XTick'),XStretch(1),XStretch(2),[0 0],TickAcc(1)); %[00] just dummy reading
	set(gca, 'XTick',Ticks, 'XTickLabel',TickLabel);

	%max plot location from http://nibot-lab.livejournal.com/73290.html
	%units are normalised -> WHOLE window (0,0,1,1) !
	pos=get(gca, 'OuterPosition') - ...
		 get(gca, 'TightInset') * [-1 0 1 0; 0 -1 0 1; 0 0 1 0; 0 0 0 1]; 
   %move it slightly to make room
   AxisMoveCorr = get(OrgAxis,'TickLength');
   AxisMoveCorr=AxisMoveCorr(1); %only 2D tick value 
   %so I will make a space
   pos = [pos(1)+AxisMoveCorr pos(2) pos(3)-AxisMoveCorr pos(4) ];
   set(OrgAxis, 'Position', pos); 

   %lets the magic begins
   set(OrgAxis,'Visible','off');
   
if ~isempty(YRange)

   for idx=1:size(YRange,1)
      %Matlab messess up position if axis ratio was changed
      %pos=get(OrgAxis,'Position');
      %plotboxpos gives U true pos
      pos=plotboxpos(OrgAxis);
      [Ticks TickLabel newPos]=GetTicks(get(OrgAxis,'YTick'),YRange(idx,1),YRange(idx,2),[pos(2) pos(4)],TickAcc(2));
      %and now move axis back
      pos=[pos(1)-AxisMoveCorr newPos(1) pos(3) newPos(2)]; 
      NewAxis(end+1)=axes('Position',pos,'YAxisLocation','left',...
           'Color','none','YColor','k','YTick',Ticks,'YTickLabel',TickLabel,...
           'YLim',[Ticks(1) Ticks(end)],'XTick',[],'XTickLabel','','XColor',BgColor); %top
      set(gca,'TickLength',get(gca,'TickLength')./2) % TickLength [2DLength 3DLength]
%       uistack(NewAxis(end),'bottom'); %move it to the bottom
   end
   ylabel(YLabel);
   uistack(OrgAxis,'bottom'); %move our orginal plot to the bottom
end 


%now let sort our X
if ~isempty(XRange)
   for idx=1:size(XRange,1)
%       pos=get(OrgAxis,'Position');
      pos=plotboxpos(OrgAxis);
      [Ticks TickLabel newPos]=GetTicks(get(OrgAxis,'XTick'),XRange(idx,1),XRange(idx,2),[pos(1) pos(3)],TickAcc(1));
      pos=[newPos(1) pos(2) newPos(2) pos(4)];
   %     pos=[newPos(1) pos(2) newPos(2) 0.0001]; %last val to make sure X grid will not overlap Y one
       NewAxis(end+1)=axes('Position',pos,'YTick',[],'YColor',BgColor,'Color','none',...
         'XLim',[Ticks(1) Ticks(end)],'XTick',Ticks,'XTickLabel',TickLabel);
%       uistack( NewAxis(end),'bottom'); %move it to the bottom

   end;
   title(Title,'FontSize',DefaulTextSize+2);
   xlabel(XLabel);
%    uistack(OrgAxis,'bottom'); %move our orginal plot to the bottom
end
if GridOn
   set(gca,'XGrid','on','XMinorGrid','off','GridLineStyle', ':');
end
set(gca,'TickLength',get(gca,'TickLength')./2);
end


%SUPPORT FUNCTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [Ticks TicksLabel NewAxisLenght]=GetTicks(Ticks,TickMin,TickMax,AxisLenght,OutputAcc)
%it will prepare visual plot with axis indicating min/max values
% To plot new axis it will calculate new ticks and new axis position
%cut orginal tick range to match min/max range icluding min/max values and calculate new pos for the axis
%IN: Ticks - orginal ticks, try get(gca,'YTick') for ex
%	TickMin,TickMax new limits, AxisLenght is the orginal axis lenght [start lenght]
% taken from positon 2nd or 3rd (l,b,w,h), for ex a=get(gca,'Position');a(1,3)

%get org dim: unit st end
Org_range = [AxisLenght(2)/(Ticks(end)-Ticks(1)) Ticks(1) Ticks(end)];

CutOffRange = 3; %if less then 30% from last tick
	%get range
   ticksRange=Ticks(2)-Ticks(1);
	Ticks=Ticks(Ticks>=TickMin);
	Ticks=Ticks(Ticks<=TickMax);

	if (Ticks(1)-TickMin < ticksRange/CutOffRange)
		  Ticks(1)=TickMin;
	else
	   Ticks= [TickMin Ticks];
	   
	end

	if (TickMax-Ticks(end) < ticksRange/CutOffRange)
			Ticks(end)=TickMax;
	else
		Ticks= [Ticks TickMax];
   end
   %get tics
   TicksLabel=TicksLabeltfromTicks(Ticks,OutputAcc);

%estimate new axis lenght
	axisChange=[Ticks(1)-Org_range(2) Org_range(3)-Ticks(end)].*Org_range(1);
	NewAxisLenght = [AxisLenght(1)+axisChange(1) AxisLenght(2)-(sum(axisChange))];
end
%%%%Get correct tics
function [TicksLabel]=TicksLabeltfromTicks(Ticks,OutputAcc)
	AccuracyString=['%.' num2str(OutputAcc) 'f'];
	TicksLabel=num2str(Ticks',AccuracyString);
end

	%	Ticks=get(OrgAxis,'YTick'); 