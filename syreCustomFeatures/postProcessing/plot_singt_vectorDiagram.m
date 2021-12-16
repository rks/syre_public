% Copyright 2021
%
%    Licensed under the Apache License, Version 2.0 (the "License");
%    you may not use this file except in compliance with the License.
%    You may obtain a copy of the License at
%
%        http://www.apache.org/licenses/LICENSE-2.0
%
%    Unless required by applicable law or agreed to in writing, software
%    distributed under the License is distributed on an "AS IS" BASIS,
%    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%    See the License for the specific language governing permissions and
%    limitations under the License.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function plot_singt_vectorDiagram(filename,pathname)

%close all
if nargin()<2
    [filename, pathname, ~] = uigetfile([cd '\.mat'], 'LOAD DATA');
end

load([pathname filename]);

% arrow variables
r=0.1;
th=15*pi/180;
f1=-r*cos(th)+j*r*sin(th);
f2=-r*cos(th)-j*r*sin(th);

% load local variables

idq = out.id+j*out.iq;
fdq = out.fd+j*out.fq;
if exist('per','var')
    n  = per.EvalSpeed;
    p  = geo.p;
    Rs = per.Rs;
else
    n  = motorModel.WaveformSetup.EvalSpeed;
    p  = motorModel.data.p;
    Rs = motorModel.data.Rs;
end

w   = n*pi/30*p;

e = j*w*fdq;
vdq = Rs*idq+e;

IPF = cos(angle(e)-angle(idq));
PF  = cos(angle(vdq)-angle(idq));


SOL = out.SOL;
SOL.idq = SOL.id+j*SOL.iq;
SOL.fdq = SOL.fd+j*SOL.fq;
SOL.e   = j*w*SOL.fdq;
SOL.vdq = Rs*SOL.idq+SOL.e;

clc
disp('-o-o-o-o-o-o-o-o-o-o-o-o-o-o-o-o-o-o-o-o-o-o-o-o-o-o-o-')
disp(['n     = ' num2str(n) ' rpm'])
disp(['T     = ' num2str(out.T) ' Nm'])
disp(['P     = ' num2str(out.T*n*pi/30/1000) ' kW'])
disp(['|idq| = ' num2str(abs(idq)) ' Apk'])
disp(['gamma = ' num2str(angle(idq)*180/pi) ' deg'])
disp(['|fdq| = ' num2str(abs(fdq)) ' Vs'])
disp(['delta = ' num2str(angle(fdq)*180/pi) ' deg'])
disp(['e     = ' num2str(abs(e)) ' Vpk'])
disp(['|vdq| = ' num2str(abs(vdq)) ' Vpk'])
disp(['IPF   = ' num2str(abs(IPF))])
disp(['PF    = ' num2str(abs(PF))])
disp('-o-o-o-o-o-o-o-o-o-o-o-o-o-o-o-o-o-o-o-o-o-o-o-o-o-o-o-')

hfig(1) = figure();
figSetting(12,12)
set(gcf,'FileName',[pathname 'vector_diagram.fig'])
set(gca,...
    'DataAspectRatio',[1 1 1],...
    'XLim',1.1*[-1 1],...
    'XTick',[],...
    'YLim',1.1*[-1 1],...
    'YTick',[],...
    'Position',[0 0 1 1],...
    'Visible','off');
plot(1.1*[-1 1],[0 0],'-k','LineWidth',0.5,'HandleVisibility','off')
fPlot=(abs(1.1)+[f1 0 f2])*exp(j*angle(1.1));
plot(real(fPlot),imag(fPlot),'-k','LineWidth',0.5,'HandleVisibility','off')
plot([0 0],1.1*[-1 1],'-k','LineWidth',0.5,'HandleVisibility','off')
fPlot=(abs(j*1.1)+[f1 0 f2])*exp(j*angle(j*1.1));
plot(real(fPlot),imag(fPlot),'-k','LineWidth',0.5,'HandleVisibility','off')
text(1.05,0,'$d$',...
    'FontSize',14,...
    'Color','k',...
    'HorizontalAlignment','right',...
    'VerticalAlignment','bottom')
text(0,1.05,'$\,\,\,q$',...
    'FontSize',14,...
    'Color','k',...
    'HorizontalAlignment','left',...
    'VerticalAlignment','middle')

colors = get(gca,'ColorOrder');

plot(real([0 idq])/abs(idq),imag([0 idq])/abs(idq),'-','Color',colors(1,:),'DisplayName','$i_{dq}$')
fPlot=(1+[f1 0 f2])*exp(j*angle(idq));
plot(real(fPlot),imag(fPlot),'-','Color',colors(1,:))
text(real(idq)/abs(idq),imag(idq)/abs(idq),'$i_{dq}$',...
    'FontSize',14,...
    'Color',colors(1,:),...
    'HorizontalAlignment','left',...
    'VerticalAlignment','bottom')

plot(real([0 fdq])/abs(fdq),imag([0 fdq])/abs(fdq),'-','Color',colors(2,:),'DisplayName','$i_{dq}$')
fPlot=(1+[f1 0 f2])*exp(j*angle(fdq));
plot(real(fPlot),imag(fPlot),'-','Color',colors(2,:))
text(real(fdq)/abs(fdq),imag(fdq)/abs(fdq),'$\lambda_{dq}$',...
    'FontSize',14,...
    'Color',colors(2,:),...
    'HorizontalAlignment','left',...
    'VerticalAlignment','bottom')

plot(real([0 e])/abs(vdq),imag([0 e])/abs(vdq),'-','Color',colors(3,:),'DisplayName','$e$')
fPlot=(abs(e)/abs(vdq)+[f1 0 f2])*exp(j*angle(e));
plot(real(fPlot),imag(fPlot),'-','Color',colors(3,:))
text(real(e)/abs(vdq),imag(e)/abs(vdq),'$e$',...
    'FontSize',14,...
    'Color',colors(3,:),...
    'HorizontalAlignment','left',...
    'VerticalAlignment','bottom')

plot(real([0 vdq])/abs(vdq),imag([0 vdq])/abs(vdq),'-','Color',colors(4,:),'DisplayName','$v_{dq}$')
fPlot=(1+[f1 0 f2])*exp(j*angle(vdq));
plot(real(fPlot),imag(fPlot),'-','Color',colors(4,:))
text(real(vdq)/abs(vdq),imag(vdq)/abs(vdq),'$v_{dq}$',...
    'FontSize',14,...
    'Color',colors(4,:),...
    'HorizontalAlignment','left',...
    'VerticalAlignment','bottom')



hfig(2) = figure();
figSetting(12,12)
set(gcf,'FileName',[pathname 'dqPlot_ripple.fig'])
set(gca,...
    'DataAspectRatio',[1 1 1],...
    'XLim',1.1*[-1 1],...
    'XTick',[],...
    'YLim',1.1*[-1 1],...
    'YTick',[],...
    'Position',[0 0 1 1],...
    'Visible','off');
plot(1.1*[-1 1],[0 0],'-k','LineWidth',0.5,'HandleVisibility','off')
fPlot=(abs(1.1)+[f1 0 f2])*exp(j*angle(1.1));
plot(real(fPlot),imag(fPlot),'-k','LineWidth',0.5,'HandleVisibility','off')
plot([0 0],1.1*[-1 1],'-k','LineWidth',0.5,'HandleVisibility','off')
fPlot=(abs(j*1.1)+[f1 0 f2])*exp(j*angle(j*1.1));
plot(real(fPlot),imag(fPlot),'-k','LineWidth',0.5,'HandleVisibility','off')
text(1.05,0,'$d$',...
    'FontSize',14,...
    'Color','k',...
    'HorizontalAlignment','right',...
    'VerticalAlignment','bottom')
text(0,1.05,'$\,\,\,q$',...
    'FontSize',14,...
    'Color','k',...
    'HorizontalAlignment','left',...
    'VerticalAlignment','middle')

plot(...
    real(SOL.idq)/max(abs(idq)),imag(SOL.idq)/max(abs(idq)),...
    '.-','Color',colors(1,:),...
    'DisplayName','$i_{dq}$ [A]','HandleVisibility','on');
% plot(...
%     real(idq)/max(abs(idq)),imag(idq)/max(abs(idq)),...
%     'o','Color',colors(1,:),...
%     'DisplayName','$i_{dq}$ [A]');
plot(...
    real(SOL.fdq)/max(abs(fdq)),imag(SOL.fdq)/max(abs(fdq)),...
    '.-','Color',colors(2,:),...
    'DisplayName','$\lambda_{dq}$ [Vs]','HandleVisibility','on');
% plot(...
%     real(fdq)/max(abs(fdq)),imag(fdq)/max(abs(fdq)),...
%     'o','Color',colors(2,:),...
%     'DisplayName','$\lambda_{dq}$ [Vs]');
plot(...
    real(SOL.e)/max(abs(vdq)),imag(SOL.e)/max(abs(vdq)),...
    '.-','Color',colors(3,:),...
    'DisplayName','$e$ [V]','HandleVisibility','on');
% plot(...
%     real(e)/max(abs(vdq)),imag(e)/max(abs(vdq)),...
%     'o','Color',colors(3,:),...
%     'DisplayName','$e$ [V]');
plot(...
    real(SOL.vdq)/max(abs(vdq)),imag(SOL.vdq)/max(abs(vdq)),...
    '.-','Color',colors(4,:),...
    'DisplayName','$v_{dq}$ [V]','HandleVisibility','on');
% plot(...
%     real(vdq)/max(abs(vdq)),imag(vdq)/max(abs(vdq)),...
%     'o','Color',colors(4,:),...
%     'DisplayName','$v_{dq}$ [V]');

hleg = legend('show','Location','southeast');


for ii=1:length(hfig)
    savePrintFigure(hfig(ii))
end

