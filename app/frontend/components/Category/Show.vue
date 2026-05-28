<template>
    <div class="show-page">
        <div class="hero">
            <TopoBackdrop />
            <div class="hero-inner">
                <div class="hero-top">
                    <div>
                        <div class="eyebrow">🎖 Categorie</div>
                        <h1 class="title">{{ category.full_name }}</h1>
                        <div class="subtitle">
                            <span>Denumirea: {{ category.category_name }}</span>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="stat-cards">
            <div class="stat-card">
                <div class="stat-icon">⭐</div>
                <div class="stat-label">Puncte</div>
                <div class="stat-value">{{ category.points }}</div>
            </div>
            <div class="stat-card">
                <div class="stat-icon">📅</div>
                <div class="stat-label">Validitate</div>
                <div class="stat-value">{{ category.validaty_period }} ani</div>
            </div>
            <div class="stat-card accent">
                <div class="stat-icon">🏃</div>
                <div class="stat-label">Sportivi</div>
                <div class="stat-value"><a :href="`/runners?category=${category.id}`">{{ runners.length }}</a></div>
            </div>
            <div class="stat-card accent">
                <div class="stat-icon">🏅</div>
                <div class="stat-label">Rezultate</div>
                <div class="stat-value"><a :href="`/results?category=${category.id}`">{{ results.length }}</a></div>
            </div>
        </div>

        <div class="section">
            <button class="section-toggle" type="button" data-bs-toggle="collapse" data-bs-target="#runnersTable" aria-expanded="false" aria-controls="runnersTable">
                <span class="section-icon">👥</span>
                <span class="section-title">Sportivi</span>
                <span class="section-meta">{{ runners.length }}</span>
                <span class="section-caret">▾</span>
            </button>
            <div class="collapse" id="runnersTable">
                <div class="section-body">
                    <RunnersTable :elements="runners" @order="orderRunnerTable"></RunnersTable>
                </div>
            </div>
        </div>

        <div class="section">
            <button class="section-toggle" type="button" data-bs-toggle="collapse" data-bs-target="#resultsTable" aria-expanded="false" aria-controls="resultsTable">
                <span class="section-icon">🏅</span>
                <span class="section-title">Rezultate</span>
                <span class="section-meta">{{ results.length }}</span>
                <span class="section-caret">▾</span>
            </button>
            <div class="collapse" id="resultsTable">
                <div class="section-body">
                    <ResultsTable :elements="results" :hidden-columns="['result_category_name']" @order="orderResultTable"></ResultsTable>
                </div>
            </div>
        </div>

        <div class="footer-actions">
            <button class="btn btn-outline-secondary" @click="goBack">← Înapoi</button>
            <div v-if="isAdmin" class="action-group">
                <button class="btn btn-success btn-sm" @click="editElement(category)">Editează</button>
                <button class="btn btn-danger btn-sm" @click="deleteCategory(category.id)">Șterge</button>
            </div>
        </div>

        <Modal ref="modal" :category="modalElement" :isNew="false" @save="updateElement" />
    </div>
</template>
<script setup>
import { ref, onMounted } from 'vue'
import axios from '@/axios'
import Modal from './Modal.vue'
import RunnersTable from '../Runner/Table.vue'
import ResultsTable from '../Result/Table.vue'
import TopoBackdrop from '../shared/TopoBackdrop.vue'
import { isAdmin } from '@/currentUser'

const category = ref({})
const modalElement = ref({})
const modal = ref(null)
const runners = ref([])
const results = ref([])
const categoryId = ref("")
const runnerSorting = ref({
    "sorting[sort_by]": "id",
    "sorting[direction]": "asc"
})

const resultSorting = ref({
    "sorting[sort_by]": "date",
    "sorting[direction]": "desc"
})

onMounted(() => {
    categoryId.value = window.location.pathname.split('/').pop();
    getData();
    getRunners();
    getResults();
})

async function getData() {
    const res = await axios.get(`/categories/${categoryId.value}.json`)
    category.value = res.data;
}

async function getRunners() {
    runnerSorting.value["category"] = categoryId.value
    const res = await axios.get('/runners.json', { params: runnerSorting.value })
    runners.value = res.data;
}

async function getResults() {
    resultSorting.value["category"] = categoryId.value
    const res = await axios.get('/results.json', { params: resultSorting.value })
    results.value = res.data;
}

function orderRunnerTable(sortKey) {
    orderTable(sortKey, runnerSorting)
    getRunners()
}

function orderResultTable(sortKey) {
    orderTable(sortKey, resultSorting)
    getResults()
}

function orderTable(sortKey, filters) {
    const isCurrentSort = filters.value["sorting[sort_by]"] === sortKey;
    const currentDir = filters.value["sorting[direction]"];

    filters.value["sorting[direction]"] = (isCurrentSort && currentDir === "asc") ? "desc" : "asc";
    filters.value["sorting[sort_by]"] = sortKey;
}

function editElement(category) {
    modalElement.value = { ...category }
    modal.value.show()
}

function updateElement(categoryData, done) {
    axios.patch(`/categories/${categoryData.id}.json`, { category: categoryData }).then(res => {
        category.value = res.data
        done()
    })
}

function deleteCategory(id) {
    if (confirm('Esti sigur ca vrei sa stergi această categorie?')) {
        axios.delete(`/categories/${id}`).then(() => {
            window.location = document.referrer || "/categories"
        })
    }
}

function goBack() {
    window.location = document.referrer || "/categories"
}
</script>

<style scoped src="../shared/show.css"></style>
