<template>
  <div class="show-page">
    <div class="hero">
      <TopoBackdrop />
      <div class="hero-inner">
        <div class="eyebrow">📥 Import</div>
        <h1 class="title">Încarcă rezultate</h1>
        <div class="subtitle">
          <span>Format acceptat:</span>
          <span class="dot">·</span>
          <span><b>JSON</b></span>
          <span class="dot">·</span>
          <span><b>HTML</b> (SportOrg)</span>
        </div>
      </div>
    </div>

    <div class="section">
      <div class="section-card">
        <form :action="formAction" method="POST" enctype="multipart/form-data" class="upload-form">
          <input type="hidden" name="authenticity_token" :value="csrfToken" />

          <label class="field">
            <span class="field-label">📁 Fișierul cu rezultate</span>
            <input
              type="file"
              name="path"
              accept=".json,.html"
              required
              class="file-input"
              @change="onFileChange"
            />
            <span v-if="fileName" class="file-meta">Selectat: <b>{{ fileName }}</b></span>
          </label>

          <div class="field">
            <span class="field-label">🏃 Tipul cursei</span>
            <div class="toggle-group">
              <label class="toggle-pill" :class="{ active: !relay }">
                <input type="radio" :value="false" v-model="relay" />
                Individuală
              </label>
              <label class="toggle-pill" :class="{ active: relay }">
                <input type="radio" :value="true" v-model="relay" />
                Ștafetă
              </label>
              <input type="hidden" name="relay" :value="relay ? '1' : ''" />
            </div>
          </div>

          <div v-if="relay" class="field">
            <span class="field-label">🔁 Tipul ștafetei</span>
            <div class="toggle-group">
              <label class="toggle-pill" :class="{ active: relayType === 'classic' }">
                <input type="radio" name="relay_type" value="classic" v-model="relayType" />
                Clasică <span class="hint">(3 etape)</span>
              </label>
              <label class="toggle-pill" :class="{ active: relayType === 'sprint' }">
                <input type="radio" name="relay_type" value="sprint" v-model="relayType" />
                Sprint <span class="hint">(4 etape, 2M+2F)</span>
              </label>
            </div>
          </div>

          <div class="actions">
            <button type="submit" class="btn btn-success btn-lg upload-btn">
              ⬆️ Încarcă
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue';
import TopoBackdrop from '../shared/TopoBackdrop.vue';

const csrfToken =
  document.querySelector('meta[name="csrf-token"]')?.getAttribute('content');

const relay     = ref(false);
const relayType = ref('classic');
const fileName  = ref('');

const formAction = computed(() =>
  relay.value ? '/parser/file_relay_results' : '/parser/file_results'
);

function onFileChange(event) {
  fileName.value = event.target.files?.[0]?.name || '';
}
</script>

<style scoped src="../shared/show.css"></style>

<style scoped>
.section-card {
  background: white;
  border: 1px solid #d6e4d8;
  border-radius: 14px;
  padding: 1.8rem 2rem;
  box-shadow: 0 4px 20px -8px rgba(20, 83, 45, 0.18);
}

.upload-form {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
  max-width: 640px;
  margin: 0 auto;
}

.field {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.field-label {
  font-size: 0.85rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  color: #4f6b54;
}

.file-input {
  border: 2px dashed #d6e4d8;
  background: #f8faf5;
  padding: 1rem;
  border-radius: 12px;
  font-size: 0.95rem;
  cursor: pointer;
  transition: border-color 0.15s, background 0.15s;
}
.file-input:hover, .file-input:focus {
  border-color: #1f5f3a;
  background: #f1f5e8;
  outline: none;
}

.file-meta {
  font-size: 0.85rem;
  color: #4f6b54;
}

.toggle-group {
  display: flex;
  gap: 0.5rem;
  flex-wrap: wrap;
}

.toggle-pill {
  background: #f1f5e8;
  border: 1px solid #d6e4d8;
  color: #2d4a30;
  border-radius: 999px;
  padding: 0.55rem 1.1rem;
  font-weight: 600;
  font-size: 0.95rem;
  cursor: pointer;
  transition: all 0.15s;
  display: inline-flex;
  align-items: center;
  gap: 0.4rem;
}
.toggle-pill input { display: none; }
.toggle-pill:hover { background: #e1ecd0; }
.toggle-pill.active {
  background: linear-gradient(135deg, #1f5f3a, #2d7a4c);
  color: white;
  border-color: transparent;
  box-shadow: 0 4px 14px -4px rgba(20, 83, 45, 0.6);
}
.toggle-pill .hint {
  font-size: 0.78rem;
  opacity: 0.7;
  font-weight: 500;
}
.toggle-pill.active .hint { opacity: 0.85; }

.actions {
  display: flex;
  justify-content: flex-end;
  margin-top: 0.5rem;
}

.upload-btn {
  padding: 0.7rem 2rem;
  font-weight: 700;
  border-radius: 12px;
  box-shadow: 0 4px 14px -4px rgba(31, 95, 58, 0.5);
}
</style>
