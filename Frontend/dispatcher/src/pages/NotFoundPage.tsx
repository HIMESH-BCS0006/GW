import React from 'react';
import { Link } from 'react-router-dom';

export const NotFoundPage: React.FC = () => {
  return (
    <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-12 text-center my-12">
      <h1 className="text-4xl font-extrabold text-indigo-600">404</h1>
      <p className="text-lg font-medium text-gray-900 mt-2">Page Not Found</p>
      <p className="text-sm text-gray-500 mt-1 mb-6">
        The requested dispatcher console route does not exist.
      </p>
      <Link
        to="/"
        className="inline-block bg-indigo-600 hover:bg-indigo-700 text-white font-medium text-sm px-4 py-2 rounded-md shadow-sm transition-colors"
      >
        Back to Dashboard
      </Link>
    </div>
  );
};
