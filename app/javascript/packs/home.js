// app/javascript/packs/home.js

document.addEventListener('DOMContentLoaded', () => {
    // Add animation class to elements as they appear in viewport
    const animateOnScroll = () => {
      const elements = document.querySelectorAll('.animate-on-scroll');
      
      elements.forEach(element => {
        const elementTop = element.getBoundingClientRect().top;
        const elementVisible = 150;
        
        if (elementTop < window.innerHeight - elementVisible) {
          element.classList.add('active');
        }
      });
    };
    
    // Add hover effects to feature cards
    const featureCards = document.querySelectorAll('.bg-gray-900.p-6.rounded-xl');
    featureCards.forEach(card => {
      card.classList.add('feature-card');
    });
    
    // Add floating animation to the logo
    const logo = document.querySelector('svg');
    if (logo) {
      logo.classList.add('float-animation');
    }
    
    // Add pulse animation to CTA buttons
    const ctaButtons = document.querySelectorAll('.bg-indigo-600, .bg-purple-600');
    ctaButtons.forEach(button => {
      button.classList.add('pulse-animation');
    });
    
    // Count up animation for statistics
    const stats = document.querySelectorAll('.text-4xl.font-bold.text-indigo-400');
    
    const countUp = (element, target) => {
      const text = element.innerText;
      const suffix = text.replace(/[0-9]/g, '');
      const number = parseInt(text.replace(/\D/g,''));
      let count = 0;
      const increment = Math.ceil(number / 50);
      const interval = setInterval(() => {
        count += increment;
        if (count >= number) {
          clearInterval(interval);
          element.innerText = target;
        } else {
          element.innerText = count + suffix;
        }
      }, 30);
    };
    
    // Initialize count up when statistics section is in view
    const startCountUp = () => {
      const statsSection = document.querySelector('.grid.grid-cols-1.md\\:grid-cols-2.lg\\:grid-cols-4');
      if (!statsSection) return;
      
      const sectionTop = statsSection.getBoundingClientRect().top;
      if (sectionTop < window.innerHeight - 100) {
        stats.forEach(stat => {
          countUp(stat, stat.innerText);
        });
        window.removeEventListener('scroll', startCountUp);
      }
    };
    
    // Add event listeners
    window.addEventListener('scroll', animateOnScroll);
    window.addEventListener('scroll', startCountUp);
    
    // Initialize animations on load
    animateOnScroll();
    startCountUp();
  });