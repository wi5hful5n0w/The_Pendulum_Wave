
%%%%%%%%%%%%%%%%%%%%%%
%
%   201503120 Jun Young Park
%   juny1905@naver.com
%
%   Dept. of Embedded Systems Engineering
%
%   Incheon Nat'l University
%   
%   Unit : Metric
%
%   - The Linear Systems Project : Pendulum waves -
% 
%   Reference : STL Reader
%   - https://www.mathworks.com/matlabcentral/fileexchange/22409-stl-file-reader
%
%%%%%%%%%%%%%%%%%%%%%%

clc; clear;



% Define Pendulums

k=0.001; % Attenuation Constant

n = 15; % Number of Pendulums
d = 6; % Distance between pins d [cm]
f_min = 40;% Minimum Frequency per Minute
P = 11:d:100; % Point Interval
Z_vec = linspace(0,0,n); % 1xn of 0 vector
I_vec = linspace(1,1,n); % 1xn of 1 vector

[x,y,z] = sphere(10); % Make the spheric surface

% Define the line length constant [cm]
L = Pendulum_Length(n,f_min)*100; % The predefined function to get length of the length vector

% % % Enable the errors.
% for i = 1:n
%      L(i) = L(i)+(0.5*rand(1)-0.25);
% end
% % ----------------------

omega = sqrt(9.8./L); % Angular speed [rad/s]
theta = Z_vec; % Initialize theta vector into 1x15 zero vector

%Load the external model
fv = stlread('hanger_zero.stl');

x_pin_s = [P;Z_vec;Z_vec;I_vec]; % Start point of the line
x_pendulum = [P+(d/2) ;Z_vec;-(L);I_vec]; % The pendulum point
x_pin_e = [P+d;Z_vec;Z_vec;I_vec]; % End point of the line
info = sprintf("Number of pendulums : %d [pcs] | Frequency of longest pendulum : %d [times/min]\nDistance between pins : %d [cm]\n",n,f_min,d);
pytha_L = sqrt(L.^2+(d/2)^2); % length of the actual rope
disp(info)
disp("The length of pendulums"); disp(L);
disp("The euclidean length of pendulums"); disp(pytha_L);

% Initialize Line Vector and Transform Matrix
for i=1:n
    v(:,:,i) = [x_pin_s(:,i) x_pendulum(:,i) x_pin_e(:,i)];
    A(:,:,i) = zeros(4);
end

% Define View Property (in Spherical Coordinate)
View_Point = [0, 45];

% Video Recording Initialization
% video = VideoWriter('Prototype_Jun_Motion');
% open(video);

% Graph Position Initialization
set(gcf, 'Position', [0, 0, 1080, 1080])


% For CUDA Processing
% - If your device doesn't support cuda,
% replace line below and disable the follwing 5 lines.

% v_GPU = v;
% omega_GPU=omega;
% A_GPU=A;
% theta_GPU = theta;

disp(gpuDevice(1)) % Display GPU Device
v_GPU = gpuArray(v); % Make main matrix to GPUArray
omega_GPU = gpuArray(omega); % Make omega matrix to GPUArray
A_GPU = gpuArray(A); % Transform matrix for GPU
theta_GPU = gpuArray(theta); % theta vector for GPU

imp = @(t) exp(-k*t)*sin(omega_GPU*t); % Damped Harmonic Motion

clear omega A theta v L Z_vec I_vec x_end x_pin_s x_pin_e P pytha_L % Free Unused Memory Space

for t = 0 : 0.45 :70*10
    tic % Startpoint of the stopwatch
    theta_GPU = (1/5)*imp(t-(pi/6)); % Get current pendulum degree by using the variable t for function imp(t)
    % Setting [Az, El] to move the POV
    if (t <150)
        Az = t*(3/10) +45;
        El = 25;
    end
    if(t >=150 && t < 190)
        Az = 90;
        El = 25 - (t-150)*25/40;
    end
    if(t >= 190 && t < 260)
        Az = 90 - (t-190)*45/70;
        El = 0;
    end
    if(t >= 260 && t < 360)
        Az = 45;
        El = (t-260)*25/100;
    end
    if(t >= 360 && t < 490)
        Az = 45 + (t-360)*45/130;
        El = 25 - (t-360)*5/130;
    end
    if(t>=490 && t < 530)
        Az = 90;
        El = 20 + (t-490)*5/40;
    end
    if(t>=530 && t < 600)
        Az = 90;
        El = 25 - (t-530)*25/70;
    end
    if(t>=600 && t < 640)
        Az = 90-(t-600)*45/40;
        El = (t-600)*25/40;
    end
    % End point of setting the POV
    
    for i=1:n % Tranform Lines for theta angle for 15 pendulums
        A_GPU(:,:,i) =  [1  0   0   2;
                                      0 cos(theta_GPU(i)) -sin(theta_GPU(i)) 28;
                                      0 sin(theta_GPU(i)) cos(theta_GPU(i)) 147.5;
                                      0 0 0 1]; % Transform matrix for theta (Roll)
        Y_GPU(:,:,i) = A_GPU(:,:,i)*v_GPU(:,:,i); % Rotate in x
    end
    
    clf
    
    axis([-30,150,-50,130,0,170]) % Set extent of each axis
    axis square; % Hold the aspect ratio.
    
    hold on % Keep drawing
    
    for i=1:n % Draw each pendulums
        % The lines
        pl=line(Y_GPU(1,:,i),Y_GPU(2,:,i),Y_GPU(3,:,i),'linestyle',':','color','red');
        % The balls
        surf(2*x+Y_GPU(1,2,i),2*y+Y_GPU(2,2,i),2*z+Y_GPU(3,2,i)-2,'FaceColor',[0.65,0.5,0],'LineStyle','none', 'AmbientStrength', 0.7)  % May Slow Down
    end
    
    info = sprintf('Linear System - 2nd Group (%.2f Second, [%.2d, %.2d])',t/10,Az,El);
    title(info); % Put the information on the plot.
    view([Az El]) % Set the POV in [Az El]

    % Draw the external model (Hanger)
    patch(fv,'FaceColor',       [0.4 0.1 0], ...
         'EdgeColor',       'none',        ...
         'FaceLighting',    'gouraud',     ...
         'AmbientStrength', 0.7, ...
         'FaceAlpha',0.3); % For transparent
     
    % Add a camera light, and tone down the specular highlighting
    camlight('headlight');
    material('dull');
    
    grid on
    hold off
    
    pause(0.0000001)
    
%     mo = getframe(gcf);
%     writeVideo(video,mo);
    
    toc % Endpoint of the stopwatch
end
close(video)
    