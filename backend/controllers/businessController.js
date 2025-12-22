const { executeQuery, findOne, updateRecord, insertRecord } = require('../config/database');

// Get business info
const getBusiness = async (req, res) => {
  try {
    const result = await executeQuery(
      'SELECT * FROM business WHERE is_active = true ORDER BY id DESC LIMIT 1'
    );

    if (!result.success) {
      return res.status(500).json({
        success: false,
        message: 'Database error'
      });
    }

    if (result.data.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Business info not found'
      });
    }

    res.json({
      success: true,
      data: result.data[0]
    });
  } catch (error) {
    console.error('Get business error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Update business info
const updateBusiness = async (req, res) => {
  try {
    const {
      nama_usaha,
      pemilik,
      alamat,
      telepon,
      email,
      deskripsi,
      kategori,
      logo
    } = req.body;

    // Validate required fields
    if (!nama_usaha || !pemilik || !alamat || !telepon) {
      return res.status(400).json({
        success: false,
        message: 'Nama usaha, pemilik, alamat, dan telepon wajib diisi'
      });
    }

    // Get current business
    const currentResult = await executeQuery(
      'SELECT * FROM business WHERE is_active = true ORDER BY id DESC LIMIT 1'
    );

    if (!currentResult.success) {
      return res.status(500).json({
        success: false,
        message: 'Database error'
      });
    }

    let businessId;
    if (currentResult.data.length > 0) {
      businessId = currentResult.data[0].id;
      
      // Update existing business
      const updateResult = await executeQuery(
        `UPDATE business 
         SET nama_usaha = ?, pemilik = ?, alamat = ?, telepon = ?, 
             email = ?, deskripsi = ?, kategori = ?, logo = ?,
             updated_at = CURRENT_TIMESTAMP
         WHERE id = ?`,
        [nama_usaha, pemilik, alamat, telepon, email, deskripsi, kategori || 'Retail', logo, businessId]
      );

      if (!updateResult.success) {
        return res.status(500).json({
          success: false,
          message: 'Failed to update business'
        });
      }
    } else {
      // Insert new business
      const insertResult = await executeQuery(
        `INSERT INTO business (nama_usaha, pemilik, alamat, telepon, email, deskripsi, kategori, logo) 
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
        [nama_usaha, pemilik, alamat, telepon, email, deskripsi, kategori || 'Retail', logo]
      );

      if (!insertResult.success) {
        return res.status(500).json({
          success: false,
          message: 'Failed to create business'
        });
      }
      
      businessId = insertResult.data.insertId;
    }

    // Get updated business
    const updatedResult = await executeQuery(
      'SELECT * FROM business WHERE id = ?',
      [businessId]
    );

    if (!updatedResult.success || updatedResult.data.length === 0) {
      return res.status(500).json({
        success: false,
        message: 'Failed to fetch updated business'
      });
    }

    res.json({
      success: true,
      message: 'Business info updated successfully',
      business: updatedResult.data[0]
    });
  } catch (error) {
    console.error('Update business error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

module.exports = {
  getBusiness,
  updateBusiness
};
