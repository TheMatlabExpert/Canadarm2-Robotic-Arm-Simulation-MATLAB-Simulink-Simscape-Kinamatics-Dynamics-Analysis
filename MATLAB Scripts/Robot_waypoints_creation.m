
data_x = out.X.Data;
data_y = out.Y.Data;
data_z = out.Z.Data;

% Create a 3D matrix containing all the points of the trajectory
data_x = reshape(data_x, length(data_x), 1);
data_y = reshape(data_y, length(data_x), 1);
data_z = reshape(data_z, length(data_x), 1);

% Concatenate the arrays along the second dimension to create a 3000x3 matrix
trajectory_matrix = [data_x, data_y, data_z];

% Display the resulting 3D matrix
