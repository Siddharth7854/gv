const express = require('express');
// Use app.get('dbService') instead of direct import
// const dbService = require('../config/database');

const router = express.Router();

// Get all categories
router.get('/', async (req, res) => {
  try {
    const result = await dbService.executeQuery(`
      SELECT category_id, category_name, description
      FROM Categories
      WHERE is_active = 1
      ORDER BY category_name ASC
    `);

    res.json({
      success: true,
      categories: result.recordset
    });

  } catch (error) {
    console.error('Fetch categories error:', error);
    res.status(500).json({
      error: 'Fetch failed',
      message: error.message
    });
  }
});

// Get category by ID
router.get('/:category_id', async (req, res) => {
  try {
    const category_id = parseInt(req.params.category_id);

    const result = await dbService.executeQuery(`
      SELECT category_id, category_name, description, created_at
      FROM Categories
      WHERE category_id = @category_id AND is_active = 1
    `, { category_id });

    if (result.recordset.length === 0) {
      return res.status(404).json({
        error: 'Not found',
        message: 'Category not found'
      });
    }

    // Get grievance count for this category
    const countResult = await dbService.executeQuery(`
      SELECT COUNT(*) as grievance_count
      FROM Grievances
      WHERE category_id = @category_id
    `, { category_id });

    const category = result.recordset[0];
    category.grievance_count = countResult.recordset[0].grievance_count;

    res.json({
      success: true,
      category
    });

  } catch (error) {
    console.error('Fetch category error:', error);
    res.status(500).json({
      error: 'Fetch failed',
      message: error.message
    });
  }
});

module.exports = router;
