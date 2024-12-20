clear;
clc;
% Get the current folder path
current_folder = pwd;

% Generate a path string for all subfolders using genpath
all_subfolders_path = genpath(current_folder);

% Add the path to the MATLAB search path using addpath
addpath(all_subfolders_path);

% Display confirmation message
disp('Successfully added subfolders to the path.');
load('Trajectory.mat')
open('Canadarm2.slx')
open('Canadarm2_Robot_only.slx')

%% Define the DH parameters for the robot

% Define the joint angles for the robot

alpha1 = pi/2;       % Angle for joint 1
alpha2 = pi/2;       % Angle for joint 2
alpha3 = pi;         % Angle for joint 3
alpha4 = 0;          % Angle for joint 4
alpha5 = -pi/2;      % Angle for joint 5
alpha6 = pi/2;       % Angle for joint 6

% Define the link offsets for the robot (a or r)
r1 = 0;              % Offset for link 1
r2 = 0;              % Offset for link 2
r3 = 300;            % Offset for link 3
r4 = 300;            % Offset for link 4
r5 = 0;              % Offset for link 5
r6 = 50;             % Offset for link 6

% Define the link lengths for the robot
d1 = 10;             % Length of link 1
d2 = 30;             % Length of link 2
d3 = 50;             % Length of link 3
d4 = 30;             % Length of link 4
d5 = 50;             % Length of link 5
d6 = 50;             % Length of link 6

% Create a Link object for each link with specified dynamic parameters
% Define the DH parameters for each link in the robot
L(1) = Link('d', d1, 'a', r1, 'alpha', alpha1, 'offset', pi);       % Link 1
L(2) = Link('d', d2, 'a', r2, 'alpha', alpha2, 'offset', 0);        % Link 2
L(3) = Link('d', d3, 'a', r3, 'alpha', alpha3, 'offset', 0);        % Link 3
L(4) = Link('d', d4, 'a', r4, 'alpha', alpha4, 'offset', 0);        % Link 4
L(5) = Link('d', d5, 'a', r5, 'alpha', alpha5, 'offset', pi);       % Link 5
L(6) = Link('d', d6, 'a', r6, 'alpha', alpha6, 'offset', -pi/2);    % Link 6

% Combine the links to create the robot model
robot = SerialLink(L,'name','Canadarm2');
% Display information about the robot
figure;
q0 = zeros(1,length(L)); 
% Example joint angles
plot(robot, q0);         % Plot the robot with initial joint angles

%%    %%%%%%%%%%%%%%     Forward Kinematics      %%%%%%%%%%%%%%
%    (q1, q2, q3, q4, q5, q6) --------------------------> (x, y, z)

%        ~~~~~~~~~~   Simple Robot Animation   ~~~~~~~~~~ 

time = (0:.5:10)';            % Generate a time vector

qr = [0, 0, pi/12,0, pi/16, pi/2];   % Final joint angles

Q = jtraj(q0, qr, time);     % Generate joint coordinate trajectory
figure;
robot.plot(Q);               % Plot the robot animation

% Create timeseries for each joint angle q1 to q5
ts_q1 = timeseries(Q(:, 1), time);
ts_q2 = timeseries(Q(:, 2), time);
ts_q3 = timeseries(Q(:, 3), time);
ts_q4 = timeseries(Q(:, 4), time);
ts_q5 = timeseries(Q(:, 5), time);
ts_q6 = timeseries(Q(:, 6), time);

% Simulate the motion control of the robot model
sim('Canadarm2_Robot_only.slx');




%%    %%%%%%%%%%%%%%     Inverse Kinematics      %%%%%%%%%%%%%%
%      (x, y, z)  -------------------------->  (q1, q2, q3, q4, q5, q6 )
%       ~~~~~~  Simple Trajectory between two points  ~~~~~~

% Define the start and destination points
T1 = transl(0, 400, 0);      % Start point
T2 = transl(60, 200, -600);  % Destination
num_points = 20;             % Number of points for trajectory

% Compute a Cartesian path
T = ctraj(T1, T2, num_points);

% Extract x, y, and z coordinates from the homogeneous transformation matrices
x = T(1, 4, :);  % x coordinates
y = T(2, 4, :);  % y coordinates
z = T(3, 4, :);  % z coordinates

% Reshape x, y, and z to 1D arrays
x = reshape(x, [1, num_points]);
y = reshape(y, [1, num_points]);
z = reshape(z, [1, num_points]);

% Plot the trajectory
figure;
plot3(x, y, z);
xlabel('X');
ylabel('Y');
zlabel('Z');
title('Trajectory between Two Points');
zlim([min(z) - 100, max(z) + 100]); % Increase Z interval by 100 units
xlim([min(x) - 100, max(x) + 100]); % Increase Z interval by 100 units
ylim([min(y) - 100, max(y) + 100]); % Increase Z interval by 50 units

%%
% Initialize Q matrix to store joint angles for each time step
Q = zeros(num_points, robot.n);

q_init = [0, 0, 0, 0, 0, 0];  % Initial joint angles
for i = 1:num_points
    xx = x(i);
    yy = y(i);
    zz = z(i);
    
    % Define the desired end-effector pose
    T_desired = transl(xx, yy, zz);

    % Calculate inverse kinematics
    ik = robot.ikine(T_desired, q_init, 'mask', [1, 1, 1, 0, 0, 0]);
    
    % Plot the robot
%     plot(robot, ik);
    
    % Save the joint angles
    Q(i, :) = ik;
    
    % Update initial joint angles for the next iteration
    q_init = ik;
end

% Q matrix now contains the joint angles for the whole trajectory
% Create time vector
time = linspace(0, 10, num_points);

% Create timeseries for each joint angle q1 to q5
ts_q1 = timeseries(Q(:, 1), time);
ts_q2 = timeseries(Q(:, 2), time);
ts_q3 = timeseries(Q(:, 3), time);
ts_q4 = timeseries(Q(:, 4), time);
ts_q5 = timeseries(Q(:, 5), time);
ts_q6 = timeseries(Q(:, 6), time);


%Plot joint space trajectory
figure;
subplot(3,2,1); plot(Q(:,1)); xlabel('Time (s)'); ylabel('Joint 1 (rad)');
subplot(3,2,2); plot(Q(:,2)); xlabel('Time (s)'); ylabel('Joint 2 (rad)');
subplot(3,2,3); plot(Q(:,3)); xlabel('Time (s)'); ylabel('Joint 3 (rad)');
subplot(3,2,4); plot(Q(:,4)); xlabel('Time (s)'); ylabel('Joint 4 (rad)');
subplot(3,2,5); plot(Q(:,5)); xlabel('Time (s)'); ylabel('Joint 5 (rad)');
subplot(3,2,6); plot(Q(:,6)); xlabel('Time (s)'); ylabel('Joint 6 (rad)');
%%
% Simulate the motion control using Simulink
modelName = 'Canadarm2.slx';
sim(modelName);




%%                     Jacobian Calculation & Sigularity
 
%  This code calculates the Jacobian matrix for a robotic arm at a specific joint configuration q. 
%  It demonstrates two ways to compute the Jacobian: one with respect to the world coordinate 
%  frame (robot.jacob0) and another with respect to the end-effector coordinate frame (robot.jacobe). 
%  It then calculates and displays the determinant of the Jacobian matrix,
%  which provides insight into the manipulability of the robot at that configuration.

%  The Jacobian  helps in identifying singularities in the robot's configuration space, 
%  where the manipulator loses its ability to move freely. These singular configurations can 
%  be problematic for control algorithms and require special handling.

% Choose a particular joint angle configuration for the robot
q = [0.1 0.75 -2.25 0 .75 0];  % Joint angles in radians

% Compute the Jacobian in the world coordinate frame
J = robot.jacob0(q);  % Jacobian matrix with respect to the base frame

% Alternatively, the Jacobian can be expressed in the end-effector frame
J = robot.jacobe(q);  % Jacobian matrix with respect to the end-effector frame

% Calculate the determinant of the Jacobian matrix
det_J = det(J);  % Determinant of the Jacobian matrix

% Display the determinant of the Jacobian matrix
disp(['Determinant of the Jacobian matrix: ', num2str(det_J)]);

%%   %%%%%%%%%%%%%%      Dynamics Analysis   %%%%%%%%%%%%%%

% Define physical parameters for the robot links
iss_DataFile;
% Inertia tensor for the first link, values represent inertia around the x, y, and z axes, assuming the link is a rigid body
I = [0.01, 0, 0; 0, 0.02, 0; 0, 0, 0.01] * 100;

% Damping coefficient for the joint connected to the first link is 0.1 Nm*s/rad
B = 0.1;

% Coulomb friction for the first joint, applying 0.2 Nm in the positive direction and -0.2 Nm in the negative direction of motion
Tc = [0.2, -0.2];

% Gearbox ratio for the joint connected to the first link is 50:1
G = 50;

% Rotor inertia of the motor for the first link is 0.0005 kg*m^2
Jm = 0.0005;

% Define the DH parameters and physical properties for each link

L(1) = Link('d', d1, 'a', r1, 'alpha', alpha1, 'offset', pi/2, 'm', smiData.Solid(4).mass, 'r', smiData.Solid(4).CoM, 'I', I, 'B', B, 'Tc', Tc, 'G', G, 'Jm', Jm);                                      
L(2) = Link('d', d2, 'a', r2, 'alpha', alpha2, 'offset', -pi/2, 'm', smiData.Solid(1).mass, 'r', smiData.Solid(1).CoM, 'I', I, 'B', B, 'Tc', Tc, 'G', G, 'Jm', Jm);                                                                                                             
L(3) = Link('d', d3, 'a', r3, 'alpha', alpha3, 'offset', pi, 'm', smiData.Solid(3).mass, 'r', smiData.Solid(3).CoM, 'I', I, 'B', B, 'Tc', Tc, 'G', G, 'Jm', Jm);  
L(4) = Link('d', d4, 'a', r4, 'alpha', alpha4, 'offset', 0, 'm', smiData.Solid(5).mass, 'r', smiData.Solid(5).CoM, 'I', I, 'B', B, 'Tc', Tc, 'G', G, 'Jm', Jm);  
L(5) = Link('d', d5, 'a', r5, 'alpha', alpha5, 'offset', pi/2, 'm', smiData.Solid(2).mass, 'r', smiData.Solid(2).CoM, 'I', I, 'B', B, 'Tc', Tc, 'G', G, 'Jm', Jm);  
L(6) = Link('d', d6, 'a', r6, 'alpha', alpha6, 'offset', -pi/2, 'm', smiData.Solid(6).mass, 'r', smiData.Solid(6).CoM, 'I', I, 'B', B, 'Tc', Tc, 'G', G, 'Jm', Jm);  

% Combine the links to create the robot model
robot = SerialLink(L, 'name', 'Canadarm2');


%%        %%%%%%%%%%%%%%          Forward Dynamics         %%%%%%%%%%%%%%
% Set initial joint angles to zero
qz = [0, 0, 0, 0, 0, 0];

% Perform forward dynamics simulation with no friction
[t, q, qd] = robot.nofriction().fdyn(0.1, @torque_function, qz);
%%
% Plot joint motion over time
figure;
for i = 1:6
    subplot(2, 3, i);
    plot(t, q(:, i), 'LineWidth', 2);
    title(['Joint ', num2str(i), ' Motion']);
    xlabel('Time (s)');
    ylabel('Motion (rad)');
end

%%
Q=q;

% Create time vector
time = t*10;

% Create timeseries for each joint angle q1 to q5
ts_q1 = timeseries(Q(:, 1), time);
ts_q2 = timeseries(Q(:, 2), time);
ts_q3 = timeseries(Q(:, 3), time);
ts_q4 = timeseries(Q(:, 4), time);
ts_q5 = timeseries(Q(:, 5), time);
ts_q6 = timeseries(Q(:, 6), time);

% Simulate the motion control using Simulink
modelName = 'Canadarm2_Robot_only.slx';
sim(modelName);

%%    %%%%%%%%%%%%%%     Inverse  Dynamics   %%%%%%%%%%%%%%

% Transpose Q matrix to match the expected format
q = Q';

% Calculate joint velocities and accelerations
qd = diff(q')';    % Joint velocities
qdd = diff(qd')';  % Joint accelerations

% Preallocate the torque array
tau = zeros(size(q));

% Calculate the inverse dynamics for each time step
for i = 1:length(Q) - 1
    if i == length(Q) - 1
        % At the last time step, velocities and accelerations are zero
        tau(:, i) = robot.rne(q(:, i)', zeros(1, 6), zeros(1, 6));
    else
        tau(:, i) = robot.rne(q(:, i)', qd(:, i)', qdd(:, i)');
    end
end

t = linspace(0, 10, length(Q));  % Time from 0 to 2 seconds

% Plot the joint torques
figure;
for i = 1:6
    subplot(2, 3, i);
    plot(t, tau(i, :), 'LineWidth', 2);
    title(['Joint ', num2str(i), ' Torques']);
    xlabel('Time (s)');
    ylabel('Torque (Nm)');
end

%%
% Define the torque function that generates sinusoidal torques for all six joints
function TAU = torque_function(ROBOT, T, Q, QD)
    % Define the amplitude of the torque for each joint
    A = [1; 8; 6; 4; 2; 1]*1000;

    % Define the frequency of the torque for each joint
    omega = [1; 1.5; 2; 2.5; 3; 3.5]*0.01;
    
    % Define the phase offset for each joint
    phase = [0; pi/6; pi/4; pi/3; pi/2; 2*pi/3];

    % Calculate the sinusoidal torque for each joint
    TAU = A.*cos(omega*T' + phase);
end


