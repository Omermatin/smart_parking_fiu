Project Overview

The Smart Parking Recommendation system is a Flutter-based mobile feature designed to optimize student parking at Florida International University (FIU). It analyzes a student’s class schedule and the real-time availability of parking garages to recommend the best parking slot, reducing walking distance and saving time.

This project was developed as part of a Sprinternship with PantherSoft and is expected to be integrated into the official FIU Mobile App with potential future enhancements.

Problem Statement

Students at FIU often face difficulty finding available parking close to their classes, leading to:

Late arrivals

Increased walking distance across campus

Frustration and inefficiency

The goal of this project is to automate parking selection using a schedule-aware recommendation algorithm, prioritizing convenience and real-time availability.

Key Features

Schedule-Aware Recommendations

Inputs: Student class schedule (term, courses, meeting times, building locations)

Logic: Calculates optimal parking garage based on proximity to first class of the day and class timings throughout the day.

Real-Time Garage Data Integration

Consumes API data for all FIU garages, including:

Garage type (garage vs. lot)

Current student/other vehicle occupancy

Latitude/longitude coordinates

Intelligent Parking Algorithm

Filters only “garage” type entries

Prioritizes garages with available student spaces

Handles multi-class days to suggest parking that minimizes walking across multiple buildings

Flutter-Based UI

Clean and responsive interface

Allows students to view garage recommendations in real-time

Technical Highlights

Flutter & Dart: Frontend interface with state management and responsive design

REST API Integration: Fetches student schedule and garage availability

Local Algorithmic Processing: All recommendation logic is handled on-device; no backend server required

Data Parsing & Modeling: JSON responses are mapped to custom Dart data models

Scalable Architecture: Easily extendable to include new features like parking history, AI-based predictions, and alternative routes
